# -*- coding: utf-8 -*-
rspec_readed = begin
  require "rubygems"
  require "spec"
  true
rescue Object
  false
end

require "galaxy_tool/errors"

if rspec_readed
  require "tempfile"

  module GalaxyTool
    module Matcher
      def self.included(mod)
        Spec::Matchers.define :require_option do |option|
          match do |tool|
            tool.require_options.include?(option)
          end
        end
        
        Spec::Matchers.define :set_default_option_value do |option, default_value|
          match do |tool|
            tool.options[option] == default_value
          end
        end

        Spec::Matchers.define :accept_option do |name, switch|
          match do |tool|
            tool.option_definitions.any? do |od|
              od.first == name &&
                (od.last[:short] =~ /^#{switch}/ ||
                 od.last[:long] =~ /^#{switch}/)
            end
          end
        end
        
        Spec::Matchers.define :accept_option_with_argument do |name, switch|
          match do |tool|
            tool.option_definitions.any? do |od|
              od.first == name &&
                (od.last[:short] =~ /^#{switch}( .+)?$/ ||
                 od.last[:long] =~ /^#{switch}( .+)?$/) &&
                (od.last[:short] =~ /^[^ ]+ [^ ]+$/ ||
                 od.last[:long] =~ /^[^ ]+ [^ ]+$/)
            end
          end
        end

        Spec::Matchers.define :accept_option_at_pattern_with do |name, pattern|
          match do |tool|
            tool.option_definitions.any? do |od|
              od.first == name &&
                od.last[:pattern] == pattern
            end
          end
        end
        
        Spec::Matchers.define :evaluate_option do |switch, value, expected|
          match do |tool|
            tool.evaluate_option(switch, value) == expected
          end
        end
        
        Spec::Matchers.define :reject_option do |option, value|
          match do |tool|
            pattern = tool.reject_patterns[option]
            case pattern
            when Proc
              pattern.call(value)
            else
              pattern === value
            end
          end
        end

        Spec::Matchers.define :be_output do |content|
          actual_content = proc{ |io| 
            case io
            when Tempfile
              File.read(io.path)
            when StringIO
              io.string
            end
          }

          match do |io|
            actual_content[io] == content
          end

          failure_message_for_should do |io|
            "Expected file to be output #{content.inspect}, but actual to be output #{actual_content[io].inspect}"
          end
        end
      end
      
      def stub_file(content=nil)
        stub = Tempfile.open("galaxy_tool_stub")
        stub.print content if content
        stub.close
        stub
      end
      
      def stub_stdout
        sio = StringIO.new
        File.stub!(:open).and_return{|*args| args.last.kind_of?(Proc) ? open(*args[0..-2], &args.last) : open(*args) }
        File.should_receive(:open).with('/dev/stdout', 'a').and_return {|path, mode, block| block.call(sio) }
        sio
      end
    end
  end
end
