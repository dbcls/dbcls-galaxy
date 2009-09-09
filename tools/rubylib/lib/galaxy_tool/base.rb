# -*- coding: utf-8 -*-
require "set"
require "optparse"

require "galaxy_tool/errors"

module GalaxyTool
  class Base
    class << self
      def new(*args, &block)
        o = super
        after_new_procs.each do |pr|
          pr.call(o)
        end
        o.setup_optparse!
        o
      end
      
      def after_new_procs
        @after_new_procs ||= []
      end
      
      def after_new(&block)
        after_new_procs << block
      end
      
      def option_banner(banner)
        after_new {|o| o.optparse.banner = banner }
      end
      
      def option(name, opt)
        after_new {|o| o.option_definitions << [name, opt] }
      end
      
      def option_output(opt)
        option(:output, {:required => true}.merge(opt))
      end
      
      def option_info(opt)
        option(:info, {:default => "/dev/stdout"}.merge(opt))
      end
      
      def option_error_handler(&block)
        after_new {|o| o.option_error_handler(&block) }
      end
    end
    
    def option_definitions
      @option_definitions ||= []
    end
    
    def options
      @options ||= {}
    end
    
    def optparse
      unless @optparse
        @optparse ||= OptionParser.new
        @optparse.on("--dryrun", TrueClass, 'for test execution and no effect.'){|arg| options[:dryrun] = arg }
      end
      @optparse
    end

    def evaluate_option(switch, value)
      if (o = option_definitions.find {|od| od.last[:short] =~ /^#{switch}( .+)?$/ || od.last[:long] =~ /^#{switch}( .+)?$/ })
        if pr = o.last[:proc]
          pr.call(value)
        else
          value
        end
      else
        nil
      end
    end
    
    def require_options
      @require_options ||= []
      @require_options.uniq!
      @require_options
    end

    def reject_patterns
      @reject_patterns ||= {}
    end
    
    def option_error_handler(&block)
      @option_error_handler ||= proc {|optparse, exception|
        $stderr.puts "Error: " + exception.message
        raise exception
      }
      if block_given?
        @option_error_handler = block
      else
        @option_error_handler
      end
    end

    def setup_optparse!
      option_definitions.each do |name, opt|
        args = [:short, :long, :class, :pattern, :description].select{|k| opt[k] }.map{|k| opt[k] }
        require_options << name if opt[:required]
        reject_patterns[name] = opt[:reject] if opt[:reject]
        options[name] = opt[:default] unless opt[:default] == nil
        optparse.on(*args) do |arg|
          if pr = opt[:proc]
            options[name] = pr.call(arg)
          else
            options[name] = arg
          end
        end
      end
    end

    def check_requires
      require_options.each do |r|
        raise RequiredOptionNotFoundError, "#{r.to_s} option not specified." unless options[r]
      end
    end
    
    def check_rejects
      reject_patterns.each do |n, p|
        raise RejectedOptionError, "#{n.to_s} option is a rejected pattern." if p.kind_of?(Proc) ? p.call(options[n]) : options[n] =~ p
      end
    end

    def setup_system_option!
      options[:info] ||= '/dev/stdout'
      options[:output] ||= '/dev/stdout'
    end
    
    def parse!(argv)
      optparse.parse!(argv)
      check_requires
      check_rejects
      setup_system_option!
    rescue
      raise unless option_error_handler
      option_error_handler.call(optparse, $!)
    end

    def dryrun
      puts "options:"
      options.keys.sort_by{|k| k.to_s }.each do |key|
        puts "  #{key} => #{options[key].inspect}"
      end
    end

    def output
      options[:output]
    end

    def exit(code, exc)
      Kernel.exit(code)
    end

    def main(output)
      raise NotImplementedError
    end
    
    def run(argv=ARGV)
      parse!(argv) rescue exit(1, $!)
      File.open(options[:info], 'a') {|o| info o } if respond_to?(:info)

      if options[:dryrun]
        dryrun
      else
        File.open(output, 'a') {|o|
          main o
        }
      end
    end  
  end
end
