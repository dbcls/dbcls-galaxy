#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"

class PfamLocationGenerator < GalaxyTool::Base
  option_banner "Usage: #{$0} --pfam-id-list-file <filepath> -o <output-filepath> [-i <info-filepath>]"

  option :pfam_id_list,
    :long => "--pfam-id-list-file <filepath>",
    :class => String,
    :description => "read pfam id list from <filepath>.",
    :proc => proc {|file| File.read(file).split("\n").map{|id| id.split("\t")[0].chomp }.uniq },
    :required => true

  option_output :short => "-o",
    :long => "--output <filepath>",
    :description => "use <filepath> as output file path."

  option_info :long => "--info <filepath>",
    :description => "use <filepath> as info file path."

  option_error_handler do |optparse, exception|
    $stderr.puts "Error: " + exception.message
    $stderr.puts optparse.help
    raise exception
  end

  def main(output)
    options[:pfam_id_list].each do |id|
      output.print "http://pfam.sanger.ac.uk/family?entry=#{ id }\n"
    end
  end
end

if $0 == __FILE__
  PfamLocationGenerator.new.run(ARGV)
end
