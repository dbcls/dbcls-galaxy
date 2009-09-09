#!/usr/bin/env ruby
require File.expand_path("util", File.dirname(__FILE__))

def tool_name(tool_id)
  snake_to_upper_camel(tool_id)
end

def expand_variables(str, vars)
  vars.each do |k, v|
    str.gsub!(k){ v }
  end
  str
end

def variables(tool_id)
  {
    "__tool_id__" => tool_id,
    "__tool_name__" => tool_name(tool_id)
  }
end

def generate_files(tool_id, tool_path)
  templates_path = File.expand_path("templates", File.dirname(__FILE__))
  
  [".sh", ".xml"].each do |ext|
    template = File.read(File.expand_path("__tool__"+ext, templates_path))
    File.open(File.expand_path(tool_id+ext, tool_path), "w+") do |f|
      f.print expand_variables(template, variables(tool_id))
    end
  end
end

if $0 == __FILE__
  begin
    generate_files(ARGV[0], ARGV[1])
  rescue
    abort
  end
end
