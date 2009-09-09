#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$: << File.expand_path('../rubylib/lib', File.dirname(__FILE__))
require "galaxy_tool"

class MedlineSearchWithBiomedicalNer < GalaxyTool::Base

  option :medline_abstracts,
    :long => "--medlines-file <filepath>",
    :class => String,
    :description => "read medline abstracts from <filepath>.",
    :required => true,
    :proc => proc {|path|
      raw_data = File.read(path)
      cutted_data = raw_data.split("\n").map{|l| l.split("\t")}

      result = []
      cutted_data.each do |row|
        Integer(row[0]) rescue raise GalaxyTool::ParseError
        raise GalaxyTool::ParseError unless row[1] =~ /^(A|T)$/
        Integer(row[2]) rescue raise GalaxyTool::ParseError

        unless matched = result.find{|l| l[:id] == row[0] }
          matched = {:id => row[0], :title => {}, :abstract => {}}
          result.push matched
        end
        attr = row[1] =~ /t/i ? :title : :abstract
        matched[attr][row[2]] = row[3]
      end
      result
    }

  option :ner_results,
    :long => "--ner-results-file <filepath>",
    :class => String,
    :description => "read NER results from <filepath>.",
    :required => true,
    :proc => proc {|path|
      raw_data = File.read(path)
      cutted_data = raw_data.split("\n").map{|l| l.split("\t")}
      
      result = []
      cutted_data.each do |row|
        Integer(row[0]) rescue raise GalaxyTool::ParseError
        raise GalaxyTool::ParseError unless row[1] =~ /^(A|T)$/
        Integer(row[2]) rescue raise GalaxyTool::ParseError
        Integer(row[5]) rescue raise GalaxyTool::ParseError
        Integer(row[6]) rescue raise GalaxyTool::ParseError

        unless matched = result.find{|l| l[:id] == row[0] }
          matched = {:id => row[0], :title => {}, :abstract => {}}
          result.push matched
        end
        attr = row[1] =~ /t/i ? :title : :abstract    
        matched[attr][row[2]] ||= []
        matched[attr][row[2]].push({
          :class => row[3],
          :term => row[4],
          :begin => Integer(row[5]),
          :end => Integer(row[6]),
          :db_id => row[7]
        })
      end
      result
    }

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

  def emphasys_sentence_by_text(sentence, ner)
    nol = 0
    result = ""
    started_ner = []
    sentence.scan(/./) do |c|
      ner.select {|i| i[:begin] == nol }.each do |n|
        result += "[["
        started_ner.unshift n
      end
      result += c
      started_ner.select {|i| i[:end] == nol+1 }.each do |n|
        result += "<#{n[:class]}>]]"
        started_ner.delete n
      end
      nol += 1
    end
    return result
  end

  def ners_by_sentence(ner, pmid, attr, sentence_id)
    if ner_by_pmid = ner.find {|i| i[:id] == pmid}
      if ner_by_sentence = ner_by_pmid[attr][sentence_id]
        return ner_by_sentence
      end
    end
    return []
  end

  def emphasys_by_text(medline_abstracts, ner_results)
    result = nil
    StringIO.open do |sio|
      medline_abstracts.each do |ma|
        sio.puts "PMID:"
        sio.puts("  " + ma[:id].to_s)
        sio.puts "Title:"
        ma[:title].sort_by{|a, b| a[0] <=> b[0] }.each do |key, value|
          ners = ners_by_sentence(ner_results, ma[:id], :title, key)
          sio.puts("  " + emphasys_sentence_by_text(value, ners))
        end
        sio.puts "Abstract:"
        ma[:abstract].sort_by{|a, b| a[0] <=> b[0] }.each do |key, value|
          ners = ners_by_sentence(ner_results, ma[:id], :abstract, key)
          sio.puts("  " + emphasys_sentence_by_text(value, ners))
        end
        sio.puts
      end
      result = sio.string
    end
    
    result
  end

  def main(output)
    output.print emphasys_by_text(options[:medline_abstracts], options[:ner_results])
  end
end

if $0 == __FILE__
  MedlineSearchWithBiomedicalNer.new.run(ARGV)
end
