#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "cgi"
require "open-uri"
require "tempfile"
require "rubygems"
require "json"

class RelatedPNEArticles < GalaxyTool::Base
  ControlTableRecord = Struct.new(:pmid, :english, :japanese)

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

  def make_pmid_file(medlines)
    path = nil
    Tempfile.open('pmid_file') do |f|
      path = f.path
      medlines.each_line do |l|
        if m = l.match(/(^.+)\t/)
          f.puts m[1]
        end
      end
    end
    path
  end

  def make_control_tables_output
    path = nil
    Tempfile.open('control_tables_output') do |f|
      path = f.path
    end
    path
  end

  def control_tables_command(pmid_path, output_path)
    "sh /opt/services/galaxy/related_pne/src/customized_control_tables/control_table.sh t2 '#{pmid_path}' '#{output_path}' /opt/services/galaxy/related_pne/src/customized_control_tables"
  end

  def control_tables(pmid_path, output_path)
    `#{control_tables_command(pmid_path, output_path)}`
  end
  
  def transrate_to_japanese(medlines)
    pmid_path = make_pmid_file(medlines)
    control_tables_output = make_control_tables_output
    control_tables(pmid_path, control_tables_output)

    japanese_queries = []
    File.read(control_tables_output).each_line do |l|
      if m = l.match(/^(.+)\t(.+)\t(.+)$/)
        japanese_queries.push ControlTableRecord.new(m[1], m[2], m[3])
      end
    end

    File.unlink(pmid_path)
    File.unlink(control_tables_output)

    japanese_queries
  end

  def search_title(pmid)
    uri = "http://togows.dbcls.jp/entry/pubmed/#{CGI.escape(pmid)}/title"
    io = OpenURI.open_uri(uri)
    io.read.chomp
  ensure
    io.close if io && !io.closed?
  end

  def search_pne(japanese)
    uri = "http://lifesciencedb.jp/pne/json_api.php?phrase=#{CGI.escape(japanese)}&outputStyle=JSON&titleLength=0"
    io = OpenURI.open_uri(uri)
    io.read
  ensure
    io.close if io && !io.closed?
  end

  def related_pne_article(ct_record, output)
    medline_title = search_title(ct_record.pmid)
    result = JSON.parse(search_pne(ct_record.japanese))["result"]
    return unless result
    
    result.each do |r|
      output.print ct_record.pmid
      output.print "\t"
      output.print medline_title
      output.print "\t"
      output.print ["title", "url"].map{|k| r[k] }.join("\t")
      output.print "\n"
    end
  end

  def info(info_out)
  end

  def main(output)
    transrate_to_japanese(options[:query]).each do |cr_record|
      related_pne_article(cr_record, output)
    end
  end
end

if $0 == __FILE__
  RelatedPNEArticles.new.run(ARGV)
end
