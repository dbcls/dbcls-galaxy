#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "optparse"

args = {
  :output => '-',  
}

opts = OptionParser.new
opts.version = "0.1.0"
opts.release = nil
opts.banner = "Usage: #{opts.program_name} [options]"
opts.on("--pmid-list PMID_LIST", String, "PMID list file.") {|file| args[:pmid_list] = File.read(file).split("\n").map{|pmid| pmid.chomp }.uniq }
opts.on("-o", "--output [FILENAME]", "Output file name.  If this option isn't specified, the program output to Standard Output.") do |output|
  args[:output] = output
end
opts.parse!(ARGV)

if args[:output] == '-'
  output = $stdout
else
  output = File.open(args[:output], 'w')
end

response = args[:pmid_list].inject([]) do |r, i|
  r += ["ゲノム", "遺伝子"].map{|q| { :id => i, :query => q } }
end

response.each do |i|
  output.print([:id, :query].map{|m| i[m] }.join("\t") + "\n")
end

output.close
