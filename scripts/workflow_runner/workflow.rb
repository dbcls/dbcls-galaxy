#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../../tools/rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "galaxy"
require "dataset"

class WorkflowRunner < GalaxyTool::Base
  class Workflow < Struct.new(:id, :name); end

  option_banner "Usage: #{$0} --user-id <user-id> --workflow-id <workflow-id> --input-dataset <filepath>"

  option :user_id,
    :short => "-u",
    :long => "--user-id <user-id>",
    :class => String,
    :description => "use <user-id> as galaxy user identifier. ex) foo@example.com",
    :required => true

  option :workflow_id,
    :short => "-w",
    :long => "--workflow-id <workflow-id>",
    :class => String,
    :description => "use <workflow-id> as galaxy workflow ID."

  option :input_dataset,
    :short => "-i",
    :long => "--input-dataset <path>",
    :class => String,
    :description => "use <path> as input dataset for running workflow.",
    :proc => proc {|file| File.read(file) }

  option :list,
    :short => "-l",
    :long => "--list",
    :class => TrueClass,  
    :description => "view workflow list."

  option_error_handler do |optparse, exception|
    $stderr.puts "Error: " + exception.message
    $stderr.puts optparse.help
    raise exception
  end

  def dataset_url(dataset)
    "#{Galaxy::BASE_URL}/datasets/#{dataset.id}/display/index"
  end

  def setup
    Galaxy.establish_agent(options[:user_id])
  end

  def workflows
    run_workflow_url_regexp = /^\/workflow\/run\?id=(.+)/
    Galaxy.agent.get Galaxy::BASE_URL + "/workflow/list_for_run"
    Galaxy.agent.page.root.css("a").select {|e|
      e["href"] =~ run_workflow_url_regexp
    }.map {|e|
      id = e["href"].match(run_workflow_url_regexp)[1]
      name = e.text
      Workflow.new(id, name)
    }
  end

  def main(output)
    setup

    if options[:list]
      workflows.each do |w|
        output.puts "#{w.id}\t#{w.name}"
      end
      return 0
    end

    raise GalaxyTool::RequiredOptionNotFoundError, "not specified a '--workflow-id' option." unless options[:workflow_id]
    
    if options[:input_dataset]
      input_dataset = Dataset.upload(options[:input_dataset]) 
      history_numbers = Galaxy.run_workflow(options[:workflow_id], input_dataset.id)
    else
      history_numbers = Galaxy.run_workflow(options[:workflow_id])
    end

    datasets = Dataset.find_by_history_numbers(history_numbers)
    Dataset.wait(datasets)

    datasets.each do |d|
      output.puts dataset_url(d)
    end
  rescue
    handler = option_error_handler
    exit(1, $!) unless handler
    handler.call(optparse, $!)
  end
end

if $0 == __FILE__
  WorkflowRunner.new.run(ARGV)
end
