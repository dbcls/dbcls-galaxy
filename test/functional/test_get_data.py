import galaxy.model
from galaxy.model.orm import *
from base.twilltestcase import TwillTestCase

class UploadData( TwillTestCase ):
    def test_000_upload_files_from_disk( self ):
        """Test uploading data files from disk"""
        self.logout()
        self.login( email='tst@bx.psu.edu' )
        history1 = galaxy.model.History.query().order_by( desc( galaxy.model.History.table.c.create_time ) ).first()
        self.upload_file( '1.bed' )
        hda1 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda1 is not None, "Problem retrieving hda1 from database"
        self.verify_dataset_correctness( '1.bed', hid=str( hda1.hid ) )
        self.upload_file( '2.bed', dbkey='hg17' )
        hda2 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda2 is not None, "Problem retrieving hda2 from database"
        self.verify_dataset_correctness( '2.bed', hid=str( hda2.hid ) )
        self.upload_file( '3.bed', dbkey='hg17', ftype='bed' )
        hda3 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda3 is not None, "Problem retrieving hda3 from database"
        self.verify_dataset_correctness( '3.bed', hid=str( hda3.hid ) )
        self.upload_file( '4.bed.gz', dbkey='hg17', ftype='bed' )
        hda4 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda4 is not None, "Problem retrieving hda4 from database"
        self.verify_dataset_correctness( '4.bed', hid=str( hda4.hid ) )
        self.upload_file( '1.scf', ftype='scf' )
        hda5 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda5 is not None, "Problem retrieving hda5 from database"
        self.verify_dataset_correctness( '1.scf', hid=str( hda5.hid ) )
        self.upload_file( '1.scf.zip', ftype='binseq.zip' )
        hda6 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda6 is not None, "Problem retrieving hda6 from database"
        self.verify_dataset_correctness( '1.scf.zip', hid=str( hda6.hid ) )
        self.delete_history( id=str( history1.id ) )
    def test_005_url_paste( self ):
        """Test url paste behavior"""
        # Deleting the current history should have created a new history
        self.check_history_for_string( 'Your history is empty' )
        history2 = galaxy.model.History.query().order_by( desc( galaxy.model.History.table.c.create_time ) ).first()
        self.upload_url_paste( 'hello world' )
        self.check_history_for_string( 'Pasted Entry' )
        self.check_history_for_string( 'hello world' )
        self.upload_url_paste( u'hello world' )
        self.check_history_for_string( 'Pasted Entry' )
        self.check_history_for_string( 'hello world' )
        self.delete_history( id=str( history2.id ) )
    def test_010_upload_encode_data( self ):
        """Test uploading encode data"""
        # Deleting the current history should have created a new history
        self.check_history_for_string( 'Your history is empty' )
        history3 = galaxy.model.History.query().order_by( desc( galaxy.model.History.table.c.create_time ) ).first()
        self.run_tool( 'encode_import_chromatin_and_chromosomes1', hg17=['cc.EarlyRepSeg.20051216.bed'] )
        self.wait()
        hda7 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda7 is not None, "Problem retrieving hda7 from database"
        self.verify_dataset_correctness( 'cc.EarlyRepSeg.20051216.bed', hid=str( hda7.hid ) )
        self.run_tool('encode_import_gencode1', hg17=['gencode.CDS.20051206.bed'])
        self.wait()
        hda8 = galaxy.model.HistoryDatasetAssociation.query() \
            .order_by( desc( galaxy.model.HistoryDatasetAssociation.table.c.create_time ) ).first()
        assert hda8 is not None, "Problem retrieving hda8 from database"
        self.verify_dataset_correctness( 'sc_3D_cds.bed', hid=str( hda8.hid ) )
        self.delete_history( id=str( history3.id ) )
    def test_015_reset_data_for_later_test_runs( self ):
        """Reseting data to enable later test runs to pass"""
        self.logout()
