#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "optparse"
require 'json'
require 'cgi'
require 'open-uri'
require 'tempfile'

###
### option analysis
###
args = {
  :output => '-',  
}
opts = OptionParser.new
opts.version = "0.1.0"
opts.release = nil
opts.banner = "Usage: #{opts.program_name} [options] QUERY"
opts.on("--query-file [QUERY_FILE]", String, "Query expression file.") {|file| args[:query] = File.read(file) }
opts.on("-q", "--query QUERY", String, "Query expression.") {|query| args[:query] = query }
opts.on("-o", "--output [FILENAME]", "Output file name.  If this option isn't specified, the program output to Standard Output.") do |output|
  args[:output] = output
end
opts.parse!(ARGV)
args[:query] = ARGV.shift unless args[:query]


###
### setup output
###
if args[:output] == '-'
  output = $stdout
else
  output = File.open(args[:output], 'w')
end


###
### transrate to Japanese query
###
pmid_path = nil
Tempfile.open('japanese_query_input') do |f|
  pmid_path = f.path
  args[:query].each_line do |l|
    if m = l.match(/(^.+)\t/)
      f.puts m[1]
    end
  end
end

japanese_query_results_path = nil
Tempfile.open('japanese_query_output') do |f|
  japanese_query_results_path = f.path
end

`sh /opt/services/galaxy/related_pne/src/customized_control_tables/control_table.sh t2 '#{pmid_path}' '#{japanese_query_results_path}' /opt/services/galaxy/related_pne/src/customized_control_tables`
japanese_query_results = File.read(japanese_query_results_path)

File.unlink(pmid_path)
File.unlink(japanese_query_results_path)

###
### make Japanese queries
###
japanese_queries = []
japanese_query_results.each_line do |l|
  if m = l.match(/^(.+)\t(.+)\t(.+)$/)
    japanese_queries.push Struct.new(:pmid, :english, :japanese).new(m[1], m[2], m[3])
  end
end


###
### search pne
###
japanese_queries.each do |query|
  medline_title = OpenURI.open_uri("http://togows.dbcls.jp/entry/pubmed/#{query.pmid}/title").read.chomp # rescue "nil"
  url = "http://lifesciencedb.jp/pne/json_api.php?phrase=#{CGI.escape(query.japanese)}&outputStyle=JSON"
  json_results = OpenURI.open_uri(url).read
  results = JSON.parse(json_results)
  if results["result"]
    results["result"].each do |r|
      output.print query.pmid
      output.print "\t"
      output.print medline_title
      output.print "\t"
      output.print ["title", "url"].map{|k| r[k] }.join("\t")
      output.print "\n"
    end
  end
end


###
### fixup output 
###
output.close
