# -*- coding: utf-8 -*-
require File.expand_path('../search_resources', File.dirname(__FILE__))

describe SearchResources, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = SearchResources.new
  end

  it "データベース名指定として '-d' オプションを受けつける" do
    @tool.should accept_option_with_argument(:database, '-d')
  end

  it "データベース名指定として '--database' オプションを受けつける" do
    @tool.should accept_option_with_argument(:database, '--database')
  end

  it "データベース名指定は必須である" do
    @tool.should require_option(:database)
  end

  it "クエリ指定として '-q' オプションを受けつける" do
    @tool.should accept_option_with_argument(:query, '-q')
  end

  it "クエリ指定として '--query' オプションを受けつける" do
    @tool.should accept_option_with_argument(:query, '--query')
  end

  it "クエリ指定として '--query-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:query, '--query-file')
  end

  it "'--query-file' オプションを、クエリが書かれたファイルのパスとして受けつける" do
    @tool.should evaluate_option('--query-file', stub_file("p53\n").path, 'p53')
  end

  it "クエリ指定は必須である" do
    @tool.should require_option(:query)
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

  describe "データベース名、クエリ、出力先を指定して実行すると" do
    before do
      @tool.should_receive(:search).with("pubmed", "p53").and_return('["123456", "789012", "111111"]')
      
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-d", "pubmed", "-q", "p53", "-o", @output.path]
    end
  
    it " TogoWS 検索を行い 1行づつ検索結果を出力先に出力する" do
      @output.should be_output("123456\n789012\n111111\n")
    end

    it "規定値のInfo出力先である標準出力にデータベース名やクエリに関する情報を出力する" do
      @info.should be_output("Searching TogoWS with database = 'pubmed', query = 'p53'\n")
    end
  end
end
