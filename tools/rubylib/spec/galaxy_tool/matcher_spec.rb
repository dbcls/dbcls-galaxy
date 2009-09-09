# -*- coding: utf-8 -*-
$: << File.expand_path('../../lib', File.dirname(__FILE__))
require "galaxy_tool/matcher.rb"

require "galaxy_tool/base.rb"

describe GalaxyTool::Matcher, "の" do
  include GalaxyTool::Matcher

  before do
    @tool = Class.new(GalaxyTool::Base).new
    @tool.instance_eval {
      @options = {
        :info => '/dev/stdout'
      }
      @require_options = [:output]
      @reject_patterns = {
        :output => /null/,
        :count => proc {|c| (1..5) === c }
      }
      @option_definitions = [
                             [
                              :output,
                              {
                                :short => '-o',
                                :long => '--output <path>',
                                :pattern => /dev/
                              }
                             ],
                             [
                              :info,
                              {
                                :long => '--info <info>',
                              }
                             ],
                             [
                              :enable_shared,
                              {
                                :long => '--enable-shared'
                              }
                             ],
                             [
                              :count,
                              {
                                :short => '-c',
                                :long => '--count <count>',
                                :proc => proc {|c| Integer(c) }
                              }
                             ]
                            ]
    }
  end
  
  describe :require_option, "は" do
    it "指定されたオプションが必須オプションの場合マッチする" do
      @tool.should require_option(:output)
    end

    it "指定されたオプションが必須オプションでない場合マッチしない" do
      @tool.should_not require_option(:input)
    end
  end

  describe :set_default_option_value, "は" do
    it "オプションが指定されたデフォルト値を持つ場合マッチする" do
      @tool.should set_default_option_value(:info, "/dev/stdout")
    end

    it "オプションが指定されたデフォルト値を持たない場合マッチしない" do
      @tool.should_not set_default_option_value(:info, "/dev/stdin")
      @tool.should_not set_default_option_value(:output, "/dev/stdout")
    end
  end

  describe :accept_option, "は" do
    it "指定されたオプションを受けつける場合マッチする" do
      @tool.should accept_option(:output, '-o')
      @tool.should accept_option(:output, '--output')
      @tool.should accept_option(:info, '--info')
      @tool.should accept_option(:enable_shared, '--enable-shared')
    end

    it "指定されたオプションを受けつけない場合マッチしない" do
      @tool.should_not accept_option(:output, '--info')
      @tool.should_not accept_option(:info, '-i')
      @tool.should_not accept_option(:input, '--output')
    end
  end

  describe :accept_option_with_argument, "は" do
    it "指定されたオプションを引数付きで受けつける場合マッチする" do
      @tool.should accept_option_with_argument(:output, '-o')
      @tool.should accept_option_with_argument(:output, '--output')
      @tool.should accept_option_with_argument(:info, '--info')
    end

    it "指定されたオプションを引数付きで受けつけない場合マッチしない" do
      @tool.should_not accept_option_with_argument(:output, '--info')
      @tool.should_not accept_option_with_argument(:info, '-i')
      @tool.should_not accept_option_with_argument(:input, '--output')
      @tool.should_not accept_option_with_argument(:enable_shared, '--enable-shared')
    end
  end

  describe :accept_option_at_pattern_with, "は" do
    it "指定されたパターンを受けつける場合マッチする" do
      @tool.should accept_option_at_pattern_with(:output, /dev/)
    end

    it "指定されたパターンを受けつけない場合マッチしない" do
      @tool.should_not accept_option_at_pattern_with(:output, /devel/)
      @tool.should_not accept_option_at_pattern_with(:info, /dev/)
    end
  end

  describe :evaluate_option, "は" do
    it "指定されたオプション引数を期待する値に評価する場合マッチする" do
      @tool.should evaluate_option('-c', '3', 3)
      @tool.should evaluate_option('-o', '/dev/null', '/dev/null')
    end

    it "指定されたオプション引数を期待する値に評価できない場合マッチしない" do
      @tool.should_not evaluate_option('-c', '3', 4)
      @tool.should_not evaluate_option('-o', '/dev/null', 'hoge')
    end
  end

  describe :require_option, "は" do
    it "指定されたオプションの値がrejectパターンと一致する場合マッチする" do
      @tool.should reject_option(:output, '/dev/null')
      @tool.should reject_option(:count, 5)
    end

    it "指定されたオプションの値がrejectパターンと一致しない場合マッチしない" do
      @tool.should_not reject_option(:output, '/dev/stdout')
      @tool.should_not reject_option(:count, 0)
    end
  end

  describe :be_output, "は" do
    it "Tempfileの中身と指定された文字列とで中身が一致する場合マッチする" do
      tempfile = Tempfile.open("matcher")
      tempfile.print "abcdefg\n"
      tempfile.close
      tempfile.should be_output("abcdefg\n")
    end

    it "Tempfileの中身と指定された文字列とで中身が一致しない場合マッチしない" do
      tempfile = Tempfile.open("matcher")
      tempfile.print "abcdefg\n"
      tempfile.close
      tempfile.should_not be_output("ABCDEFG\n")
    end

    it "StringIOの中身と指定された文字列とで中身が一致する場合マッチする" do
      sio = StringIO.new
      sio.print "abcdefg\n"
      sio.should be_output("abcdefg\n")
    end

    it "StringIOの中身と指定された文字列とで中身が一致しない場合マッチしない" do
      sio = StringIO.new
      sio.print "abcdefg\n"
      sio.should_not be_output("ABCDEFG\n")
    end
  end

  describe :stub_file, "は" do
    it "一時的なテスト用のファイルを作成する" do
      File.exist?(stub_file.path).should be_true
    end

    it "contentで初期化したファイルを作成する" do
      File.read(stub_file("abcdefg\n").path).should == "abcdefg\n"
    end
  end

  describe :stub_stdout, "は" do
    it "/dev/stdoutを'a'モードで開いた場合に、その'/dev/stdout'に書き込んだ内容を保持するテスト用のStringIOを作成する" do
      stdout = stub_stdout
      File.open('/dev/stdout', 'a') {|f| f.print "abcdefg\n" }
      stdout.string.should == "abcdefg\n"
    end
  end
end
