#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"
require "rubygems"
require "soap/wsdlDriver"
require "optparse"

class OrefilSearch < GalaxyTool::Base
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

  option :count,
    :short => "-c",
    :long => "--count <size>",
    :class => String,
    :description => "use <size> max number of results.",
    :default => 10

  option :sort_by,
    :short => "-s",
    :long => "--sort-by <way>",
    :pattern => ['relevance', 'date', 'rating'],
    :class => Integer,
    :description => "use <way> as sort-way. enable to specify 'relevance', 'date', 'rating'.",
    :default => "relevance"

  option :options,
    :long => "--options <option-names>",
    :description => "enamurate boolean option name to apply by comma separated without space. (e.g. 'hide_unfethed,feedback')",
    :proc => proc {|arg| o = arg.split(','); {:hide_unfetched => o.include?("hide_unfetched"), :feedback => o.include?("feedback") } },
  :default => {:hide_unfetched => false, :feedback => false }
  
  option_output :short => "-o",
    :long => "--output <filepath>",
    :description => "use <filepath> as output file path."

  option_info :long => "--info <filepath>",
    :description => "use <filepath> as info file path. default is standard out (/dev/stdout)."

  option_error_handler do |optparse, exception|
    $stderr.puts "Error: " + exception.message
    $stderr.puts optparse.help
    raise exception
  end

  def search(query, count, sort_by, hide_unfetched, feedback)
    wsdl = "http://orefil.dbcls.jp/search/service.wsdl"
    driver = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
    response = driver.GetResourceInfoByQueryTerm(query, count, sort_by, hide_unfetched, feedback)
    response.results
  end

  def info(info_out)
    info_out.puts "Searching OReFiL with query = '#{options[:query]}', count = '#{options[:count]}', sort-by = '#{options[:sort_by]}', hide-unfetched = #{options[:options][:hide_unfetched]}, feedback = #{options[:options][:feedback]}\n"
  end

  def main(output)
    search(options[:query], options[:count], options[:sort_by], options[:options][:hide_unfetched], options[:options][:feedback]).each do |i|
      output.print([:id, :url, :title, :rank].map{|m| i.send(m) }.join("\t") + "\n")
    end
  end
end

if $0 == __FILE__
  OrefilSearch.new.run(ARGV)
end
