#!/usr/bin/env ruby
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "open-uri"
require "cgi"
require "rubygems"
require "json"

class SearchResources < GalaxyTool::Base
  option_banner "Usage: #{$0} -d <database-name> (-q <query> | --query-file <query-file>) -o <output-filepath> [-i <info-filepath>]"

  option :database,
    :short => "-d",
    :long => "--database <name>",
    :class => String,
    :description => "use <name> as database name.",
    :required => true

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

  def info(info_out)
    info_out.puts "Searching TogoWS with database = '#{options[:database]}', query = '#{options[:query]}'"
  end

  def search(database, query)
    io = OpenURI.open_uri("http://togows.dbcls.jp/search/#{CGI.escape(database)}/#{CGI.escape(query)}.json")
    io.read
  ensure
    io.close if io && !io.closed?
  end

  def main(output)
    JSON.parse(search(options[:database], options[:query])).each do |id|
      output.print id, "\n"
    end
  end
end

if $0 == __FILE__
  SearchResources.new.run(ARGV)
end
