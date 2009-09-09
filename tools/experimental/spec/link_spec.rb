# -*- coding: utf-8 -*-
require File.expand_path('../link', File.dirname(__FILE__))

describe LinkGenerator, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = LinkGenerator.new
  end

  it "URLリストファイルのパス指定として '--url-list-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:url_list, '--url-list-file')
  end

  it "'--url-list-file' オプションを、URL一覧が書かれたファイルのパスとして受けつける" do
    @tool.should evaluate_option('--url-list-file', stub_file("http://www.hoge.com/\nhttp://www.fuga.jp/\nhttp://www.piyo.org/\n").path, ["http://www.hoge.com/", "http://www.fuga.jp/", "http://www.piyo.org/"])
  end

  it "URLリストファイルパスの指定は必須である" do
    @tool.should require_option(:url_list)
  end

  it "出力先指定として '-o' オプションを受けつける" do
    @tool.should accept_option_with_argument(:output, '-o')
  end

  it "出力先指定として '--output' オプションを受けつける" do
    @tool.should accept_option_with_argument(:output, '--output')
  end

  it "出力先指定は必須である" do
    @tool.should require_option(:output)
  end

  it "Info出力先指定として '--info' オプションを受けつける" do
    @tool.should accept_option_with_argument(:info, '--info')
  end

  it "Info出力先の規定値は標準出力である" do
    @tool.should set_default_option_value(:info, '/dev/stdout')
  end

  describe "URLリストファイルパス、出力先を指定して実行すると" do
    before do
      url_list_file = stub_file("www.hoge.com/\nhttp://www.fuga.jp/\nhttp://www.piyo.org/\n")
      @output = stub_file
      @tool.run ["--url-list-file", url_list_file.path, "-o", @output.path]
    end
    
    it " TogoWS エントリーフィールド値取得を行いIDとフィールド値をタブで区切って1行づつ検索結果を出力先に出力する" do
      @output.should be_output(<<-EOT)
<a href=\"http://www.hoge.com/\">http://www.hoge.com/</a><br/>
<a href=\"http://www.fuga.jp/\">http://www.fuga.jp/</a><br/>
<a href=\"http://www.piyo.org/\">http://www.piyo.org/</a><br/>
      EOT
    end
  end
end
