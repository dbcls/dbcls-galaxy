# -*- coding: utf-8 -*-
require File.expand_path('../orefil_search', File.dirname(__FILE__))
require 'ostruct'

describe OrefilSearch, "は" do
  include GalaxyTool::Matcher

  before do
    @tool = OrefilSearch.new
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

  it "最大結果表示件数指定として '-c' オプションを受けつける" do
    @tool.should accept_option_with_argument(:count, '-c')
  end

  it "最大結果表示件数指定として '--count' オプションを受けつける" do
    @tool.should accept_option_with_argument(:count, '--count')
  end

  it "最大結果表示件数指定の規定値は10である" do
    @tool.should set_default_option_value(:count, 10)
  end

  it "ソート方法指定として '-s' オプションを受けつける" do
    @tool.should accept_option_with_argument(:sort_by, '-s')
  end

  it "ソート方法指定として '--sort-by' オプションを受けつける" do
    @tool.should accept_option_with_argument(:sort_by, '--sort-by')
  end

  it "ソート方法指定で指定できる値は、'relevance' と 'date' と 'rating' である" do
    @tool.should accept_option_at_pattern_with(:sort_by, ['relevance', 'date', 'rating'])
  end
  
  it "ソート方法指定の規定値は 'relevance' である" do
    @tool.should set_default_option_value(:sort_by, "relevance")
  end

  it "取得不可能エントリーの非表示、疑似フィードバック指定として '--options' オプションを受けつける" do
    @tool.should accept_option_with_argument(:options, '--options')
  end

  it "取得不可能エントリーの非表示、疑似フィードバック指定の規定値は :hide_unfetched => false, :feedback => false である" do
    @tool.should set_default_option_value(:options, {:hide_unfetched => false, :feedback => false })
  end

  it "'--options' オプションを、取得不可能エントリーの非表示、疑似フィードバック指定として受付ける" do
    @tool.should evaluate_option('--options', 'hide_unfetched,feedback', {:hide_unfetched => true, :feedback => true })
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

  describe "クエリ、出力先を指定して実行すると" do
    before do
      record = Struct.new(:id, :url, :title, :rank)
      @tool.should_receive(:search).and_return [
                                                 record.new(3569, 'http://cmgm.stanford.edu/pbrown/Pat_Brown_Lab_Home_Page/Home.html', 'pbrown', 1),
                                                 record.new(16030,'http://genome.imim.es/genepredictions/', 'Precomputed Gene Predictions on Whole Genome Sequences', 2),
                                                 record.new(1976, 'http://www.genome.gov/page.cfm?pageID=10002154', 'genome.gov | Approved Sequencing Targets', 3)
                                                ]
      @query = "genome"
      @info = stub_stdout      
      @output = stub_file
      @tool.run ["-q", @query, "-o", @output.path]
    end

    it "OReFiL検索を行い、ID、URL、タイトル、ランクをタブ区切りで表示する" do
      @output.should be_output(<<-EOT)
3569	http://cmgm.stanford.edu/pbrown/Pat_Brown_Lab_Home_Page/Home.html	pbrown	1
16030	http://genome.imim.es/genepredictions/	Precomputed Gene Predictions on Whole Genome Sequences	2
1976	http://www.genome.gov/page.cfm?pageID=10002154	genome.gov | Approved Sequencing Targets	3
      EOT
    end

    it "規定値のInfo出力先である標準出力にクエリに関する情報を出力する" do
      @info.should be_output("Searching OReFiL with query = 'genome', count = '10', sort-by = 'relevance', hide-unfetched = false, feedback = false\n")
    end
  end

  describe "結果が存在しないクエリを指定して実行すると" do
    before do
      record = Struct.new(:id, :url, :title, :rank)
      @tool.should_receive(:search).and_return []

      @info = stub_stdout      
      @output = stub_file
      @tool.run ["-q", "結果無しクエリ", "-o", @output.path]
    end

    it "何も表示しない" do
      @output.should be_output("")
    end
  end
end
