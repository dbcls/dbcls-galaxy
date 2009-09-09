#!/usr/bin/env ruby
require 'rexml/document'
require File.expand_path("util", File.dirname(__FILE__))

def add_tool(element, category_id, tool_id)
  if !section = element.elements["section[@name='#{snake_to_upper_camel(category_id)}'][@id='#{category_id}']"]
    section = element.add_element("section", "name" => snake_to_upper_camel(category_id), "id" => category_id)
  end
  if !tool = section.elements["tool[@file='#{category_id}/#{tool_id}.xml']"]
    tool = section.add_element("tool", "file" => "#{category_id}/#{tool_id}.xml")
  end
  tool
end

def appended_tool_conf(xml, category_id, tool_id)
  doc = REXML::Document.new(xml)
  add_tool(doc.root, category_id, tool_id)

  new_xml = ''
  REXML::Formatters::Pretty.new(2).write(doc, new_xml)

  new_xml + "\n"
end

if $0 == __FILE__
  begin
    tool_conf, category_id, tool_id = ARGV 
    xml = File.read(tool_conf)
    File.open(tool_conf, 'w+') do |f|
      f.write appended_tool_conf(xml, category_id, tool_id)
    end
  rescue
    abort
  end
end
