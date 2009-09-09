import logging, threading, sys, os, time, subprocess, string, tempfile, re, traceback, shutil

from galaxy import util, model
from galaxy.model import mapping
from galaxy.model.orm import lazyload
from galaxy.datatypes.tabular import *
from galaxy.datatypes.interval import *
from galaxy.datatypes import metadata

import pkg_resources
pkg_resources.require( "PasteDeploy" )

from paste.deploy.converters import asbool

from Queue import Queue, Empty

log = logging.getLogger( __name__ )

# States for running a job. These are NOT the same as data states
JOB_WAIT, JOB_ERROR, JOB_INPUT_ERROR, JOB_INPUT_DELETED, JOB_OK, JOB_READY, JOB_DELETED, JOB_ADMIN_DELETED = 'wait', 'error', 'input_error', 'input_deleted', 'ok', 'ready', 'deleted', 'admin_deleted'

class JobManager( object ):
    """
    Highest level interface to job management.
    
    TODO: Currently the app accesses "job_queue" and "job_stop_queue" directly.
          This should be decoupled. 
    """
    def __init__( self, app ):
        self.app = app
        if self.app.config.get_bool( "enable_job_running", True ):
            # The dispatcher launches the underlying job runners
            self.dispatcher = DefaultJobDispatcher( app )
            # Queues for starting and stopping jobs
            self.job_queue = JobQueue( app, self.dispatcher )
            self.job_stop_queue = JobStopQueue( app, self.dispatcher )
        else:
            self.job_queue = self.job_stop_queue = NoopQueue()
    def shutdown( self ):
        self.job_queue.shutdown()
        self.job_stop_queue.shutdown()

class Sleeper( object ):
    """
    Provides a 'sleep' method that sleeps for a number of seconds *unless*
    the notify method is called (from a different thread).
    """
    def __init__( self ):
        self.condition = threading.Condition()
    def sleep( self, seconds ):
        self.condition.acquire()
        self.condition.wait( seconds )
        self.condition.release()
    def wake( self ):
        self.condition.acquire()
        self.condition.notify()
        self.condition.release()

class JobQueue( object ):
    """
    Job manager, waits for jobs to be runnable and then dispatches to 
    a JobRunner.
    """
    STOP_SIGNAL = object()
    def __init__( self, app, dispatcher ):
        """Start the job manager"""
        self.app = app
        # Should we read jobs form the database, or use an in memory queue
        self.track_jobs_in_database = app.config.get_bool( 'track_jobs_in_database', False )
        # Check if any special scheduling policy should be used. If not, default is FIFO.
        sched_policy = app.config.get('job_scheduler_policy', 'FIFO')
        # Parse the scheduler policy string. The policy class implements a special queue. 
        # Ready-to-run jobs are inserted into this queue
        if sched_policy != 'FIFO' :
            try :
                self.use_policy = True
                if ":" in sched_policy :
                    modname , policy_class = sched_policy.split(":")
                    modfields = modname.split(".")
                    module = __import__(modname)
                    for mod in modfields[1:] : module = getattr( module, mod)
                    # instantiate the policy class
                    self.squeue = getattr( module , policy_class )(self.app)
                else :
                    self.use_policy = False
                    log.info("Scheduler policy not defined as expected, defaulting to FIFO")
            except AttributeError, detail: # try may throw AttributeError
                self.use_policy = False
                log.exception("Error while loading scheduler policy class, defaulting to FIFO")
        else :
            self.use_policy = False

        log.info("job scheduler policy is %s" %sched_policy)
        # Keep track of the pid that started the job manager, only it
        # has valid threads
        self.parent_pid = os.getpid()
        # Contains new jobs. Note this is not used if track_jobs_in_database is True
        self.queue = Queue()
        
        # Contains jobs that are waiting (only use from monitor thread)
        ## This and new_jobs[] are closest to a "Job Queue"
        self.waiting = []
                
        # Helper for interruptable sleep
        self.sleeper = Sleeper()
        self.running = True
        self.dispatcher = dispatcher
        self.monitor_thread = threading.Thread( target=self.__monitor )
        self.monitor_thread.start()        
        log.info( "job manager started" )
        if app.config.get_bool( 'enable_job_recovery', True ):
            self.__check_jobs_at_startup()

    def __check_jobs_at_startup( self ):
        """
        Checks all jobs that are in the 'new', 'queued' or 'running' state in
        the database and requeues or cleans up as necessary.  Only run as the
        job manager starts.
        """
        model = self.app.model
        for job in model.Job.filter( model.Job.c.state==model.Job.states.NEW ).all():
            log.debug( "no runner: %s is still in new state, adding to the jobs queue" %job.id )
            self.queue.put( ( job.id, job.tool_id ) )
        for job in model.Job.filter( (model.Job.c.state == model.Job.states.RUNNING) | (model.Job.c.state == model.Job.states.QUEUED) ).all():
            if job.job_runner_name is None:
                log.debug( "no runner: %s is still in queued state, adding to the jobs queue" %job.id )
                self.queue.put( ( job.id, job.tool_id ) )
            else:
                job_wrapper = JobWrapper( job, self.app.toolbox.tools_by_id[ job.tool_id ], self )
                self.dispatcher.recover( job, job_wrapper )

    def __monitor( self ):
        """
        Continually iterate the waiting jobs, checking is each is ready to 
        run and dispatching if so.
        """
        # HACK: Delay until after forking, we need a way to do post fork notification!!!
        time.sleep( 10 )
        while self.running:
            try:
                self.__monitor_step()
            except:
                log.exception( "Exception in monitor_step" )
            # Sleep
            self.sleeper.sleep( 1 )

    def __monitor_step( self ):
        """
        Called repeatedly by `monitor` to process waiting jobs. Gets any new
        jobs (either from the database or from its own queue), then iterates
        over all new and waiting jobs to check the state of the jobs each
        depends on. If the job has dependencies that have not finished, it
        it goes to the waiting queue. If the job has dependencies with errors,
        it is marked as having errors and removed from the queue. Otherwise,
        the job is dispatched.
        """
        # Get an orm session
        session = mapping.Session()
        # Pull all new jobs from the queue at once
        new_jobs = []
        if self.track_jobs_in_database:
            for j in session.query( model.Job ).options( lazyload( "external_output_metadata" ), lazyload( "parameters" ) ).filter( model.Job.c.state == model.Job.states.NEW ).all():
                job = JobWrapper( j, self.app.toolbox.tools_by_id[ j.tool_id ], self )
                new_jobs.append( job )
        else:
            try:
                while 1:
                    message = self.queue.get_nowait()
                    if message is self.STOP_SIGNAL:
                        return
                    # Unpack the message
                    job_id, tool_id = message
                    # Create a job wrapper from it
                    job_entity = session.query( model.Job ).get( job_id )
                    job = JobWrapper( job_entity, self.app.toolbox.tools_by_id[ tool_id ], self )
                    # Append to watch queue
                    new_jobs.append( job )
            except Empty:
                pass
        # Iterate over new and waiting jobs and look for any that are 
        # ready to run
        new_waiting = []
        for job in ( new_jobs + self.waiting ):
            try:
                # Clear the session for each job so we get fresh states for
                # job and all datasets
                session.clear()
                # Get the real job entity corresponding to the wrapper (if we
                # are tracking in the database this is probably cached in
                # the session from the origianl query above)
                job_entity = session.query( model.Job ).get( job.job_id )
                # Check the job's dependencies, requeue if they're not done                    
                job_state = self.__check_if_ready_to_run( job, job_entity )
                if job_state == JOB_WAIT: 
                    if not self.track_jobs_in_database:
                        new_waiting.append( job )
                elif job_state == JOB_ERROR:
                    log.info( "job %d ended with an error" % job.job_id )
                elif job_state == JOB_INPUT_ERROR:
                    log.info( "job %d unable to run: one or more inputs in error state" % job.job_id )
                elif job_state == JOB_INPUT_DELETED:
                    log.info( "job %d unable to run: one or more inputs deleted" % job.job_id )
                elif job_state == JOB_READY:
                    # If special queuing is enabled, put the ready jobs in the special queue
                    if self.use_policy :
                        self.squeue.put( job ) 
                        log.debug( "job %d put in policy queue" % job.job_id )
                    else: # or dispatch the job directly
                        self.dispatcher.put( job )
                        log.debug( "job %d dispatched" % job.job_id)
                elif job_state == JOB_DELETED:
                    msg = "job %d deleted by user while still queued" % job.job_id
                    job.info = msg
                    log.debug( msg )
                elif job_state == JOB_ADMIN_DELETED:
                    job.fail( job_entity.info )
                    log.info( "job %d deleted by admin while still queued" % job.job_id )
                else:
                    msg = "unknown job state '%s' for job %d" % ( job_state, job.job_id )
                    job.info = msg
                    log.error( msg )
            except Exception, e:
                job.info = "failure running job %d: %s" % ( job.job_id, str( e ) )
                log.exception( "failure running job %d" % job.job_id )
        # Update the waiting list
        self.waiting = new_waiting
        # If special (e.g. fair) scheduling is enabled, dispatch all jobs
        # currently in the special queue    
        if self.use_policy :
            while 1:
                try:
                    sjob = self.squeue.get()
                    self.dispatcher.put( sjob )
                    log.debug( "job %d dispatched" % sjob.job_id )
                except Empty: 
                    # squeue is empty, so stop dispatching
                    break
                except Exception, e: # if something else breaks while dispatching
                    job.fail( "failure running job %d: %s" % ( sjob.job_id, str( e ) ) )
                    log.exception( "failure running job %d" % sjob.job_id )
        # Done with the session
        mapping.Session.remove()
        
    def __check_if_ready_to_run( self, job_wrapper, job ):
        """
        Check if a job is ready to run by verifying that each of its input
        datasets is ready (specifically in the OK state). If any input dataset
        has an error, fail the job and return JOB_INPUT_ERROR. If any input
        dataset is deleted, fail the job and return JOB_INPUT_DELETED.  If all
        input datasets are in OK state, return JOB_READY indicating that the
        job can be dispatched. Otherwise, return JOB_WAIT indicating that input
        datasets are still being prepared.
        """
        if job.state == model.Job.states.DELETED:
            return JOB_DELETED
        elif job.state == model.Job.states.ERROR:
            return JOB_ADMIN_DELETED
        for dataset_assoc in job.input_datasets:
            idata = dataset_assoc.dataset
            if not idata:
                continue
            # don't run jobs for which the input dataset was deleted
            if idata.deleted:
                job_wrapper.fail( "input data %d (file: %s) was deleted before the job started" % ( idata.hid, idata.file_name ) )
                return JOB_INPUT_DELETED
            # an error in the input data causes us to bail immediately
            elif idata.state == idata.states.ERROR:
                job_wrapper.fail( "input data %d is in error state" % ( idata.hid ) )
                return JOB_INPUT_ERROR
            elif idata.state != idata.states.OK:
                # need to requeue
                return JOB_WAIT
        return JOB_READY
            
    def put( self, job_id, tool ):
        """Add a job to the queue (by job identifier)"""
        if not self.track_jobs_in_database:
            self.queue.put( ( job_id, tool.id ) )
            self.sleeper.wake()
    
    def shutdown( self ):
        """Attempts to gracefully shut down the worker thread"""
        if self.parent_pid != os.getpid():
            # We're not the real job queue, do nothing
            return
        else:
            log.info( "sending stop signal to worker thread" )
            self.running = False
            if not self.track_jobs_in_database:
                self.queue.put( self.STOP_SIGNAL )
            self.sleeper.wake()
            log.info( "job queue stopped" )
            self.dispatcher.shutdown()

class JobWrapper( object ):
    """
    Wraps a 'model.Job' with convience methods for running processes and 
    state management.
    """
    def __init__(self, job, tool, queue ):
        self.job_id = job.id
        # This is immutable, we cache it for the scheduling policy to use if needed
        self.session_id = job.session_id
        self.tool = tool
        self.queue = queue
        self.app = queue.app
        self.extra_filenames = []
        self.command_line = None
        self.galaxy_lib_dir = None
        # With job outputs in the working directory, we need the working
        # directory to be set before prepare is run, or else premature deletion
        # and job recovery fail.
        self.working_directory = \
            os.path.join( self.app.config.job_working_directory, str( self.job_id ) )
        self.output_paths = None
        self.external_output_metadata = metadata.JobExternalOutputMetadataWrapper( job ) #wrapper holding the info required to restore and clean up from files used for setting metadata externally
        
    def get_param_dict( self ):
        """
        Restore the dictionary of parameters from the database.
        """
        job = model.Job.get( self.job_id )
        param_dict = dict( [ ( p.name, p.value ) for p in job.parameters ] )
        param_dict = self.tool.params_from_strings( param_dict, self.app )
        return param_dict
        
    def prepare( self ):
        """
        Prepare the job to run by creating the working directory and the
        config files.
        """
        mapping.context.current.clear() #this prevents the metadata reverting that has been seen in conjunction with the PBS job runner
        if not os.path.exists( self.working_directory ):
            os.mkdir( self.working_directory )
        # Restore parameters from the database
        job = model.Job.get( self.job_id )
        incoming = dict( [ ( p.name, p.value ) for p in job.parameters ] )
        incoming = self.tool.params_from_strings( incoming, self.app )
        # Do any validation that could not be done at job creation
        self.tool.handle_unvalidated_param_values( incoming, self.app )
        # Restore input / output data lists
        inp_data = dict( [ ( da.name, da.dataset ) for da in job.input_datasets ] )
        out_data = dict( [ ( da.name, da.dataset ) for da in job.output_datasets ] )
        # These can be passed on the command line if wanted as $userId $userEmail
        if job.history.user: # check for anonymous user!
             userId = '%d' % job.history.user.id
             userEmail = str(job.history.user.email)
        else:
             userId = 'Anonymous'
             userEmail = 'Anonymous'
        incoming['userId'] = userId
        incoming['userEmail'] = userEmail
        # Build params, done before hook so hook can use
        param_dict = self.tool.build_param_dict( incoming, inp_data, out_data, self.get_output_fnames(), self.working_directory )
        # Certain tools require tasks to be completed prior to job execution
        # ( this used to be performed in the "exec_before_job" hook, but hooks are deprecated ).
        if self.tool.tool_type is not None:
            out_data = self.tool.exec_before_job( self.queue.app, inp_data, out_data, param_dict )
        # Run the before queue ("exec_before_job") hook
        self.tool.call_hook( 'exec_before_job', self.queue.app, inp_data=inp_data, 
                             out_data=out_data, tool=self.tool, param_dict=incoming)
        mapping.context.current.flush()
        # Build any required config files
        config_filenames = self.tool.build_config_files( param_dict, self.working_directory )
        # FIXME: Build the param file (might return None, DEPRECATED)
        param_filename = self.tool.build_param_file( param_dict, self.working_directory )
        # Build the job's command line
        self.command_line = self.tool.build_command_line( param_dict )
        # FIXME: for now, tools get Galaxy's lib dir in their path
        if self.command_line and self.command_line.startswith( 'python' ):
            self.galaxy_lib_dir = os.path.abspath( "lib" ) # cwd = galaxy root
        # We need command_line persisted to the db in order for Galaxy to re-queue the job
        # if the server was stopped and restarted before the job finished
        job.command_line = self.command_line
        job.flush()
        # Return list of all extra files
        extra_filenames = config_filenames
        if param_filename is not None:
            extra_filenames.append( param_filename )
        self.param_dict = param_dict
        self.extra_filenames = extra_filenames
        return extra_filenames

    def fail( self, message, exception=False ):
        """
        Indicate job failure by setting state and message on all output 
        datasets.
        """
        job = model.Job.get( self.job_id )
        job.refresh()
        # if the job was deleted, don't fail it
        if not job.state == model.Job.states.DELETED:
            # Check if the failure is due to an exception
            if exception:
                # Save the traceback immediately in case we generate another
                # below
                job.traceback = traceback.format_exc()
                # Get the exception and let the tool attempt to generate
                # a better message
                etype, evalue, tb =  sys.exc_info()
                m = self.tool.handle_job_failure_exception( evalue )
                if m:
                    message = m
            if self.app.config.outputs_to_working_directory:
                for dataset_path in self.get_output_fnames():
                    try:
                        shutil.move( dataset_path.false_path, dataset_path.real_path )
                        log.debug( "fail(): Moved %s to %s" % ( dataset_path.false_path, dataset_path.real_path ) )
                    except ( IOError, OSError ), e:
                        log.error( "fail(): Missing output file in working directory: %s" % e )
            for dataset_assoc in job.output_datasets:
                dataset = dataset_assoc.dataset
                dataset.refresh()
                dataset.state = dataset.states.ERROR
                dataset.blurb = 'tool error'
                dataset.info = message
                dataset.set_size()
                dataset.flush()
            job.state = model.Job.states.ERROR
            job.command_line = self.command_line
            job.info = message
            job.flush()
        # If the job was deleted, just clean up
        self.cleanup()
        
    def change_state( self, state, info = False ):
        job = model.Job.get( self.job_id )
        job.refresh()
        for dataset_assoc in job.output_datasets:
            dataset = dataset_assoc.dataset
            dataset.refresh()
            dataset.state = state
            if info:
                dataset.info = info
            dataset.flush()
        if info:
            job.info = info
        job.state = state
        job.flush()

    def get_state( self ):
        job = model.Job.get( self.job_id )
        job.refresh()
        return job.state

    def set_runner( self, runner_url, external_id ):
        job = model.Job.get( self.job_id )
        job.refresh()
        job.job_runner_name = runner_url
        job.job_runner_external_id = external_id
        job.flush()
        
    def finish( self, stdout, stderr ):
        """
        Called to indicate that the associated command has been run. Updates 
        the output datasets based on stderr and stdout from the command, and
        the contents of the output files. 
        """
        # default post job setup
        mapping.context.current.clear()
        job = model.Job.get( self.job_id )
        # if the job was deleted, don't finish it
        if job.state == job.states.DELETED:
            self.cleanup()
            return
        elif job.state == job.states.ERROR:
            # Job was deleted by an administrator
            self.fail( job.info )
            return
        if stderr:
            job.state = "error"
        else:
            job.state = 'ok'
        if self.app.config.outputs_to_working_directory:
            for dataset_path in self.get_output_fnames():
                try:
                    shutil.move( dataset_path.false_path, dataset_path.real_path )
                    log.debug( "finish(): Moved %s to %s" % ( dataset_path.false_path, dataset_path.real_path ) )
                except ( IOError, OSError ):
                    self.fail( "Job %s's output dataset(s) could not be read" % job.id )
                    return
        for dataset_assoc in job.output_datasets:
            #should this also be checking library associations? - can a library item be added from a history before the job has ended? - lets not allow this to occur
            for dataset in dataset_assoc.dataset.dataset.history_associations: #need to update all associated output hdas, i.e. history was shared with job running
                dataset.blurb = 'done'
                dataset.peek  = 'no peek'
                dataset.info  = stdout + stderr
                dataset.set_size()
                if stderr:
                    dataset.blurb = "error"
                elif dataset.has_data():
                    # Only set metadata values if they are missing...
                    dataset.set_meta( overwrite = False )
                    is_multi_byte = self.tool.is_multi_byte
                    if is_multi_byte:
                        dataset.set_multi_byte_peek()
                    else:
                        dataset.set_peek()
                else:
                    dataset.blurb = "empty"
                dataset.flush()
            if stderr:
                dataset_assoc.dataset.dataset.state = model.Dataset.states.ERROR
            else:
                dataset_assoc.dataset.dataset.state = model.Dataset.states.OK
            dataset_assoc.dataset.dataset.flush()
        
        # Save stdout and stderr    
        if len( stdout ) > 32768:
            log.error( "stdout for job %d is greater than 32K, only first part will be logged to database" % job.id )
        job.stdout = stdout[:32768]
        if len( stderr ) > 32768:
            log.error( "stderr for job %d is greater than 32K, only first part will be logged to database" % job.id )
        job.stderr = stderr[:32768]  
        # custom post process setup
        inp_data = dict( [ ( da.name, da.dataset ) for da in job.input_datasets ] )
        out_data = dict( [ ( da.name, da.dataset ) for da in job.output_datasets ] )
        param_dict = dict( [ ( p.name, p.value ) for p in job.parameters ] ) # why not re-use self.param_dict here? ##dunno...probably should, this causes tools.parameters.basic.UnvalidatedValue to be used in following methods instead of validated and transformed values during i.e. running workflows
        param_dict = self.tool.params_from_strings( param_dict, self.app )
        # Check for and move associated_files
        self.tool.collect_associated_files(out_data, self.working_directory)
        # Create generated output children and primary datasets and add to param_dict
        collected_datasets = {'children':self.tool.collect_child_datasets(out_data),'primary':self.tool.collect_primary_datasets(out_data)}
        param_dict.update({'__collected_datasets__':collected_datasets})
        # Certain tools require tasks to be completed after job execution
        # ( this used to be performed in the "exec_after_process" hook, but hooks are deprecated ).
        if self.tool.tool_type is not None:
            self.tool.exec_after_process( self.queue.app, inp_data, out_data, param_dict )
        # Call 'exec_after_process' hook
        self.tool.call_hook( 'exec_after_process', self.queue.app, inp_data=inp_data, 
                             out_data=out_data, param_dict=param_dict, 
                             tool=self.tool, stdout=stdout, stderr=stderr )
        # TODO
        # validate output datasets
        job.command_line = self.command_line
        mapping.context.current.flush()
        log.debug( 'job %d ended' % self.job_id )
        self.cleanup()
        
    def cleanup( self ):
        # remove temporary files
        try:
            for fname in self.extra_filenames:
                os.remove( fname )
            if self.working_directory is not None:
                shutil.rmtree( self.working_directory )
            if self.app.config.set_metadata_externally:
                self.external_output_metadata.cleanup_external_metadata()
        except:
            log.exception( "Unable to cleanup job %d" % self.job_id )
        
    def get_command_line( self ):
        return self.command_line
    
    def get_session_id( self ):
        return self.session_id

    def get_input_fnames( self ):
        job = model.Job.get( self.job_id )
        filenames = []
        for da in job.input_datasets: #da is JobToInputDatasetAssociation object
            if da.dataset:
                filenames.append( da.dataset.file_name )
                #we will need to stage in metadata file names also
                #TODO: would be better to only stage in metadata files that are actually needed (found in command line, referenced in config files, etc.)
                for key, value in da.dataset.metadata.items():
                    if isinstance( value, model.MetadataFile ):
                        filenames.append( value.file_name )
        return filenames

    def get_output_fnames( self ):
        if self.output_paths is not None:
            return self.output_paths

        class DatasetPath( object ):
            def __init__( self, real_path, false_path = None ):
                self.real_path = real_path
                self.false_path = false_path
            def __str__( self ):
                if false_path is None:
                    return self.real_path
                else:
                    return self.false_path

        job = model.Job.get( self.job_id )
        if self.app.config.outputs_to_working_directory:
            self.output_paths = []
            for name, data in [ ( da.name, da.dataset.dataset ) for da in job.output_datasets ]:
                false_path = os.path.abspath( os.path.join( self.working_directory, "galaxy_dataset_%d.dat" % data.id ) )
                self.output_paths.append( DatasetPath( data.file_name, false_path ) )
        else:
            self.output_paths = [ DatasetPath( da.dataset.file_name ) for da in job.output_datasets ]
        return self.output_paths

    def check_output_sizes( self ):
        sizes = []
        output_paths = self.get_output_fnames()
        for outfile in [ str( o ) for o in output_paths ]:
            sizes.append( ( outfile, os.stat( outfile ).st_size ) )
        return sizes
    def setup_external_metadata( self, exec_dir = None, tmp_dir = None, dataset_files_path = None, **kwds ):
        if tmp_dir is None:
            #this dir should should relative to the exec_dir
            tmp_dir = self.app.config.new_file_path
        if dataset_files_path is None:
            dataset_files_path = self.app.model.Dataset.file_path
        job = model.Job.get( self.job_id )
        return self.external_output_metadata.setup_external_metadata( [ output_dataset_assoc.dataset for output_dataset_assoc in job.output_datasets ], exec_dir = exec_dir, tmp_dir = tmp_dir, dataset_files_path = dataset_files_path, **kwds )

class DefaultJobDispatcher( object ):
    def __init__( self, app ):
        self.app = app
        self.job_runners = {}
        start_job_runners = ["local"]
        if app.config.start_job_runners is not None:
            start_job_runners.extend( app.config.start_job_runners.split(",") )
        for runner_name in start_job_runners:
            if runner_name == "local":
                import runners.local
                self.job_runners[runner_name] = runners.local.LocalJobRunner( app )
            elif runner_name == "pbs":
                import runners.pbs
                self.job_runners[runner_name] = runners.pbs.PBSJobRunner( app )
            elif runner_name == "sge":
                import runners.sge
                self.job_runners[runner_name] = runners.sge.SGEJobRunner( app )
            else:
                log.error( "Unable to start unknown job runner: %s" %runner_name )
            
    def put( self, job_wrapper ):
        runner_name = ( job_wrapper.tool.job_runner.split(":", 1) )[0]
        log.debug( "dispatching job %d to %s runner" %( job_wrapper.job_id, runner_name ) )
        self.job_runners[runner_name].put( job_wrapper )

    def stop( self, job ):
        runner_name = ( job.job_runner_name.split(":", 1) )[0]
        log.debug( "stopping job %d in %s runner" %( job.id, runner_name ) )
        self.job_runners[runner_name].stop_job( job )

    def recover( self, job, job_wrapper ):
        runner_name = ( job.job_runner_name.split(":", 1) )[0]
        log.debug( "recovering job %d in %s runner" %( job.id, runner_name ) )
        self.job_runners[runner_name].recover( job, job_wrapper )

    def shutdown( self ):
        for runner in self.job_runners.itervalues():
            runner.shutdown()

class JobStopQueue( object ):
    """
    A queue for jobs which need to be terminated prematurely.
    """
    STOP_SIGNAL = object()
    def __init__( self, app, dispatcher ):
        self.app = app
        self.dispatcher = dispatcher

        # Keep track of the pid that started the job manager, only it
        # has valid threads
        self.parent_pid = os.getpid()
        # Contains new jobs. Note this is not used if track_jobs_in_database is True
        self.queue = Queue()

        # Contains jobs that are waiting (only use from monitor thread)
        self.waiting = []

        # Helper for interruptable sleep
        self.sleeper = Sleeper()
        self.running = True
        self.monitor_thread = threading.Thread( target=self.monitor )
        self.monitor_thread.start()        
        log.info( "job stopper started" )

    def monitor( self ):
        """
        Continually iterate the waiting jobs, stop any that are found.
        """
        # HACK: Delay until after forking, we need a way to do post fork notification!!!
        time.sleep( 10 )
        while self.running:
            try:
                self.monitor_step()
            except:
                log.exception( "Exception in monitor_step" )
            # Sleep
            self.sleeper.sleep( 1 )

    def monitor_step( self ):
        """
        Called repeatedly by `monitor` to stop jobs.
        """
        # Pull all new jobs from the queue at once
        jobs = []
        try:
            while 1:
                ( job_id, error_msg ) = self.queue.get_nowait()
                if job_id is self.STOP_SIGNAL:
                    return
                # Append to watch queue
                jobs.append( ( job_id, error_msg ) )
        except Empty:
            pass  

        for job_id, error_msg in jobs:
            job = model.Job.get( job_id )
            job.refresh()
            # if desired, error the job so we can inform the user.
            if error_msg is not None:
                job.state = job.states.ERROR
                job.info = error_msg
            else:
                job.state = job.states.DELETED
            job.flush()
            # if job is in JobQueue or FooJobRunner's put method,
            # job_runner_name will be unset and the job will be dequeued due to
            # state change above
            if job.job_runner_name is not None:
                # tell the dispatcher to stop the job
                self.dispatcher.stop( job )

    def put( self, job_id, error_msg=None ):
        self.queue.put( ( job_id, error_msg ) )

    def shutdown( self ):
        """Attempts to gracefully shut down the worker thread"""
        if self.parent_pid != os.getpid():
            # We're not the real job queue, do nothing
            return
        else:
            log.info( "sending stop signal to worker thread" )
            self.running = False
            self.queue.put( ( self.STOP_SIGNAL, None ) )
            self.sleeper.wake()
            log.info( "job stopper stopped" )

class NoopQueue( object ):
    """
    Implements the JobQueue / JobStopQueue interface but does nothing
    """
    def put( self, *args ):
        return
    def shutdown( self ):
        return

