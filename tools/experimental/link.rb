#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"

class LinkGenerator < GalaxyTool::Base
  option_banner "Usage: #{$0} --url-list-file <filepath> -o <output-filepath> [-i <info-filepath>]"

  option :url_list,
    :long => "--url-list-file <filepath>",
    :class => String,
    :description => "read url list from <filepath>.",
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
    options[:url_list].each do |url|
      if url !~ /http:\/\//
        url = "http://" + url
      end
      output.print "<a href=\"#{url}\">#{url}</a><br/>\n"
    end
  end
end

if $0 == __FILE__
  LinkGenerator.new.run(ARGV)
end
