# -*- coding: utf-8 -*-
$: << File.expand_path('../../lib', File.dirname(__FILE__))
require "galaxy_tool/base.rb"

require "tempfile"
require "stringio"

describe GalaxyTool::Base, "を継承し" do
  before do
    $stdout = @stdout = StringIO.new
    $stderr = @stderr = StringIO.new
    @output_file = Tempfile.new('galaxy_tool_output')
  end

  describe "option で :short を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :file, :short => '-f <file>'
      }.new
      @command.should_receive(:main)

      @command.run(['-f', '/dev/stdout'])
    end

    it "そのオプション指定をコマンドラインショートオプションとして解析し、オプション名をキーにしてoptionsに格納する" do
      @command.options[:file].should == '/dev/stdout'
    end
  end

  describe "option で :long を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :file, :long => '--file <file>'
      }.new
      @command.should_receive(:main)

      @command.run(['--file', '/dev/stdout'])
    end

    it "そのオプション指定をコマンドラインロングオプションとして解析し、オプション名をキーにしてoptionsに格納する" do
      @command.options[:file].should == '/dev/stdout'
    end
  end

  describe "option で :class を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :class => Integer
      }.new
      @command.should_receive(:main)

      @command.run(['--count', '300'])
    end

    it "オプション引数をそのクラスで解析し、オプション名をキーにしてoptionsに格納する" do
      @command.options[:count].should == 300
    end
  end

  describe "option で :proc を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :class => Integer, :proc => proc {|arg| Float(arg) }
      }.new
      @command.should_receive(:main)

      @command.run(['--count', '300'])
    end

    it "オプション引数を Procオブジェクトに渡して call し、その結果をオプション名をキーにして options に格納する" do
      @command.options[:count].should == 300.0
    end
  end

  describe "option で :required => true を指定して" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :required => true
      }.new
    end

    it "そのオプション指定が無い場合、エラーで終了する。" do
      @command.should_receive(:exit) {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RequiredOptionNotFoundError)
        exit(code)
      }
      proc { @command.run([]) }.should raise_error(SystemExit)
    end
  end

  describe "option で :reject を指定して" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :reject => /0/
      }.new
    end

    it "reject パターンによるオプション指定で実行した場合、エラーで終了する" do
      @command.should_receive(:exit) {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RejectedOptionError)
        exit(code)
      }
      proc { @command.run(['--count', '0']) }.should raise_error(SystemExit)
    end
  end

  describe "option で :reject を Procオブジェクトで指定して" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :reject => proc {|c| Integer(c) == 0 }
      }.new
    end

    it "reject パターンによるオプション指定で実行した場合、エラーで終了する" do
      @command.should_receive(:exit) {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RejectedOptionError)
        exit(code)
      }
      proc { @command.run(['--count', '0']) }.should raise_error(SystemExit)
    end
  end

  describe "option で :default を指定して" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :default => 1
      }.new
      @command.should_receive(:main)
    end

    it "オプションが指定されなかった場合オプションの値としてデフォルト値があてられる" do
      @command.run([])
      @command.options[:count].should == 1
    end
  end

  describe "option_output を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option_output :short => '-o', :long => '--output <path>'
      }.new
    end

    it ":output をキーにして options に格納する" do
      @command.should_receive(:main)
      @command.run(['-o', '/dev/stdout'])
      @command.options[:output].should == '/dev/stdout'
    end

    it ":output は自動的に必須オプションとなる" do
      @command.should_receive(:exit) {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RequiredOptionNotFoundError)
        exit(code)
      }
      proc { @command.run([]) }.should raise_error(SystemExit)
    end
  end

  describe "option_info を指定したら" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option_info :short => '-i', :long => '--info <path>'
      }.new
    end

    it ":info をキーにして options に格納する" do
      @command.should_receive(:main)
      @command.run(['-i', '/dev/stdout'])
      @command.options[:info].should == '/dev/stdout'
    end

    it "デフォルト値として options[:info] に '/dev/stdout' を格納する" do
      @command.should_receive(:main)
      @command.run([])
      @command.options[:info].should == '/dev/stdout'
    end
  end

  describe "option を何も指定しないとき" do
    before do
      @command = Class.new(GalaxyTool::Base).new
      @command.should_receive(:main)
      @command.run([])
    end

    it "main メソッドに標準出力が渡される" do
      @command.options[:output] = '/dev/stdout'
    end
  end

  describe "'--dryrun' オプションを指定した状態で実行したら" do
    before do
      @command = Class.new(GalaxyTool::Base).new
      @command.should_not_receive(:main)

      @command.run(['--dryrun'])
    end

    it "mainメソッドを呼ばない" do
    end

    it "標準出力に options の中身を書き出す" do
      @stdout.string.should == <<-EOT
options:
  dryrun => true
  info => "/dev/stdout"
  output => "/dev/stdout"
      EOT
    end
  end

  describe "info メソッドが定義されていれば" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        def info(output)
          output.path.should == options[:info]
        end
      }.new
      @command.should_receive(:main)
    end

    it "options[:info]をオープンしたファイルを引数として info メソッドを呼ぶ" do
      @command.run([])
    end
  end

  describe "main メソッドが定義されていなければ" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        def info(output)
          output.path.should == options[:info]
        end
      }.new
    end

    it "未実装例外を投げる" do
      proc { @command.run([]) }.should raise_error(NotImplementedError)
    end
  end

  describe "option_error_handler を設定していて" do
    before do
      handler = proc {|optparse, exception|
        exception.should be_a_kind_of(GalaxyTool::RejectedOptionError)
        raise exception
      }
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :reject => /0/
        option_error_handler(&handler)
      }.new
      @command.should_receive(:exit).and_return {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RejectedOptionError)
        Kernel.exit(code)
      }
    end

    it "解析エラーが発生するオプションを指定して実行されたら、設定されたエラーハンドラを呼ぶ" do
      proc { @command.run(['--count', '0']) }.should raise_error(SystemExit)
    end
  end

  describe "option_error_handler を設定しないで" do
    before do
      @command = Class.new(GalaxyTool::Base) {
        option :count, :long => '--count <number>', :reject => /0/
      }.new
      @command.should_receive(:exit).and_return {|code, exc|
        exc.should be_a_kind_of(GalaxyTool::RejectedOptionError)
        Kernel.exit(code)
      }
      proc { @command.run(['--count', '0']) }.should raise_error(SystemExit)
    end

    it "解析エラーが発生するオプションを指定して実行されたら、デフォルトのエラーハンドラがエラーメッセージを標準エラー出力に出力しプログラムを終了する" do
      @stderr.string.should == <<-EOT
Error: count option is a rejected pattern.
      EOT
    end
  end
end
