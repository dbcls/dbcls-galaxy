#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require 'cgi'
require 'open-uri'
require "rubygems"
require 'json'

class PNESearch < GalaxyTool::Base
  option_banner "Usage: #{$0} (-q <query> | --query-file <query-file>) -o <output-filepath> [-i <info-filepath>]"

  option :query,
    :long => "--query-file <filepath>",
    :class => String,
    :description => "read query expression from <filepath>.",
    :proc => proc {|arg| File.read(arg).chomp },
    :required => true

  option :query,
    :short => "-q",
    :long => "--query <expression>",
    :class => String,
    :description => "use <expression> as query expression.",
    :proc => proc {|arg| arg.chomp },
    :required => true,
    :reject => /\n/

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

  def info(info_out)
    info_out.puts "Searching PNE with query = '#{options[:query]}'"
  end

  def search(query)
    url = "http://lifesciencedb.jp/pne/json_api.php?phrase=#{CGI.escape(query)}&outputStyle=JSON&titleLength=0"
    io = OpenURI.open_uri(url)
    io.read
  ensure
    io.close if io && !io.closed?
  end

  def main(output)
    result = JSON.parse(search(options[:query]))["result"]
    return unless result
    
    result.each do |r|
      output.puts ["title", "url"].map{|k| r[k] }.join("\t")
    end
  end
end

if $0 == __FILE__
  PNESearch.new.run(ARGV)
end
