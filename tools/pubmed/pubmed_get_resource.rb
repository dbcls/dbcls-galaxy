#!/usr/bin/env ruby
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "optparse"
require "open-uri"
require "cgi"
require "rubygems"
require 'json'

class PubMedGetResource < GalaxyTool::Base
  option_banner "Usage: #{$0} -e <entry-id-filepath> -f <field-name> -o <output-filepath> [-i <info-filepath>]"

  option :entry_ids,
    :short => '-e',
    :long => "--entry-id-file <name>",
    :class => String,
    :description => "read entry id list from <filepath>.",
    :proc => proc {|file| File.read(file).split("\n").map{|id| id.split("\t")[0].chomp }.uniq },
    :required => true

  option :field,
    :short => "-f",
    :long => "--field <name>",
    :class => String,
    :description => "use <name> as field name.",
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

  def info(info_out)
    info_out.puts "Getting PubMed entry resource with field = '#{options[:field]}'"
  end

  def get_resources(database, ids, field)
    uri = "http://togows.dbcls.jp/entry/#{CGI.escape(database)}/#{CGI.escape(ids.join(','))}/#{CGI.escape(field)}.json"
    io = OpenURI.open_uri(uri)
    io.read
  ensure
    io.close if io && !io.closed?
  end

  def walk_json(json)
    case json
    when Hash
      json.each do |key, value|
        walk_json(value) do |v|
          yield key.to_s + "\t" + v.to_s
        end
      end
    when Array
      json.each do |item|
        yield item
      end
    else
      yield json
    end
  end

  def main(output)
    database = "ncbi-pubmed"
    JSON.parse(get_resources(database, options[:entry_ids], options[:field])).each_with_index do |v, i|
      walk_json(v) do |value|
        output.puts "#{options[:entry_ids][i]}\t#{value}"
      end
    end
  end
end

if $0 == __FILE__
  PubMedGetResource.new.run(ARGV)
end
