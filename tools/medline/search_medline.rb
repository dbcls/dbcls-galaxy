#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "open-uri"
require "cgi"

class SearchMedline < GalaxyTool::Base
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
    info_out.puts "Searching MEDLINE abstract with query = '#{options[:query]}'"
  end

  def search_title(pmid)
    url = "http://togows.dbcls.jp/entry/pubmed/#{CGI.escape(pmid)}/title"
    OpenURI.open_uri(url).read.chomp
  end

  def search(query)
    `/bin/sh /opt/services/galaxy/related_pne/src/customized_medline_search/customized_chun_search_direct_input.sh '#{query}' /dev/stdout`
  end

  def main(output)
    search(options[:query]).each_line do |l|
      pmid = l.chomp.split("\t").last
      output.puts "#{pmid}\t#{search_title(pmid)}" if pmid
    end
  end
end

if $0 == __FILE__
  SearchMedline.new.run(ARGV)
end
