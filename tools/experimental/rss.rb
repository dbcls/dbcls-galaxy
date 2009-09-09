#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "open-uri"
require "rubygems"
require 'json'

class RSSGenerator < GalaxyTool::Base
  option_banner "Usage: #{$0} --pubmed-list-file <filepath> -o <output-filepath> [-i <info-filepath>]"

  option :pubmed_list,
    :long => "--pubmed-list-file <filepath>",
    :class => String,
    :description => "read pubmed list from <filepath>.",
    :proc => proc {|file|
      File.read(file).split("\n").map do |line|
        line.split("\t")
      end
    },
    :required => true,
    :reject => proc {|lines| lines.any?{|line| line.size != 4 } }

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
    output.print "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
    output.print "<rdf:RDF\n"
    output.print "  xmlns=\"http://purl.org/rss/1.0/\"\n"
    output.print "  xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n"
    output.print "  <channel rdf:about=\"http://example.com/rss\">\n"
    output.print "    <items>\n"
    output.print "      <rdf:Seq>\n"
    
    options[:pubmed_list].each do |l|
      pmid, title, date, desc = l
      output.print "        <rdf:li rdf:resource=\"http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}\"/>\n"
    end
    
    output.print "      </rdf:Seq>\n"
    output.print "    </items>\n"
    output.print "  </channel>\n"
    options[:pubmed_list].each do |l|
      pmid, title, date, desc = l
      output.print "  <item rdf:about=\"http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}\">\n"
      output.print "    <title>#{title}</title>\n"
      output.print "    <link>http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}</link>\n"
      output.print "    <description>#{desc}</description>\n"
      output.print "    <date>#{date}</date>\n"
      output.print "  </item>\n"
    end
    output.print "</rdf:RDF>\n"
  end
end

if $0 == __FILE__
  RSSGenerator.new.run(ARGV)
end
