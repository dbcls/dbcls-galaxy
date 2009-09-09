# -*- coding: utf-8 -*-
require File.expand_path('../search_medline', File.dirname(__FILE__))

describe SearchMedline, "は" do
  include GalaxyTool::Matcher

  before do
    @tool = SearchMedline.new
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

  it "改行を含むクエリは受けつけない" do
    @tool.should reject_option(:query, "改行\nあり")
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


  describe "クエリ、出力先を指定して実行すると" do
    before do
      @tool.should_receive(:search).with("p53").and_return("1\t1430194\n2\t1567683\n3\t12673119\n4\t1357342\n5\t18510935\n")
      @tool.should_receive(:search_title).with("1430194").and_return("Cancer risks from germline p53 mutations.")
      @tool.should_receive(:search_title).with("1567683").and_return("The p53 gene in human cancer.")
      @tool.should_receive(:search_title).with("12673119").and_return("The p53 homology trap.")
      @tool.should_receive(:search_title).with("1357342").and_return("Reversible p53 expression in lung cancer.")
      @tool.should_receive(:search_title).with("18510935").and_return("SnapShot: p53 posttranslational modifications.")
      
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-q", "p53", "-o", @output.path]
    end
    
    it "MEDLINE abstract 検索を行い、ID とタイトルをタブ区切りで1行づつ検索結果を出力する" do
      @output.should be_output(<<-EOT)
1430194	Cancer risks from germline p53 mutations.
1567683	The p53 gene in human cancer.
12673119	The p53 homology trap.
1357342	Reversible p53 expression in lung cancer.
18510935	SnapShot: p53 posttranslational modifications.
      EOT
    end
    
    it "規定値のInfo出力先である標準出力にクエリに関する情報を出力する" do
      @info.should be_output("Searching MEDLINE abstract with query = 'p53'\n")
    end
  end

  describe "結果が存在しないクエリを指定して実行すると" do
    before do
      @tool.should_receive(:search).with("結果無しクエリ").and_return('')
      
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-q", "結果無しクエリ", "-o", @output.path]
    end
  
    it "なにも出力しない" do
      @output.should be_output('')
    end
  end
end
