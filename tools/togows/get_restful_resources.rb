#!/usr/bin/env ruby
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "optparse"
require "open-uri"
require "rubygems"
require 'json'
require 'net/http'

class GetRestfulResources < GalaxyTool::Base
  option_banner "Usage: #{$0} -e <entry-id-filepath> -d <database-name> -f <field-name> -o <output-filepath> [-i <info-filepath>]"

  option :entry_ids,
    :short => '-e',
    :long => "--entry-id-file <name>",
    :class => String,
    :description => "read entry id list from <filepath>.",
    :proc => proc {|file| File.read(file).split("\n").map{|id| id.split("\t")[0].chomp }.uniq },
    :required => true

  option :database,
    :short => "-d",
    :long => "--database <name>",
    :class => String,
    :description => "use <name> as database name.",
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
    info_out.puts "Getting TogoWS entry resource with database = '#{options[:database]}', field = '#{options[:field]}'"
  end

  def initialize
    @http = Http.new
  end

  def http=(new_http)
    @http = new_http
  end

  def http
    @http
  end
  
  def with_retry
    # 最大2回リトライを行う 
    begin
      begin
        yield
      rescue StandardError, Timeout::Error
        yield
      end
    rescue StandardError, Timeout::Error
      yield
    end
  end

  def get_by_batch_request(database, ids, field)
    path = "/entry/#{database}/#{ids.join(',')}/#{field}.json"
    http.get('togows.dbcls.jp', path)
  end

  def get_by_individual_request(database, ids, field)
    result = []
    ids.each do |id|
      path = "/entry/#{database}/#{id}/#{field}.json"
      # 結果が文字列の配列として返ってくるので、配列部分を取り除く
      result << JSON.parse(http.get('togows.dbcls.jp', path))[0]
    end
    result.to_json
  end

  def get_resources(database, ids, field)
    with_retry do
      begin
        get_by_batch_request(database, ids, field)
      rescue BadGatewayError
        get_by_individual_request(database, ids, field)
      end
    end
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
    JSON.parse(get_resources(options[:database], options[:entry_ids], options[:field])).each_with_index do |v, i|
      walk_json(v) do |value|
        output.puts "#{options[:entry_ids][i]}\t#{value}"
      end
    end
  end
end

class Http
  def get(host, path)
    Net::HTTP.version_1_2
    Net::HTTP.start(host, 80) {|http|
      response = http.get(path)
      if response.class == Net::HTTPBadGateway
        raise BadGatewayError.new
      else
        response.body
      end
    }
  end
end

class BadGatewayError < StandardError
end

if $0 == __FILE__
  GetRestfulResources.new.run(ARGV)
end
