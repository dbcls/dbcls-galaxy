# -*- coding: utf-8 -*-
require File.expand_path('../rss', File.dirname(__FILE__))

describe RSSGenerator, "は" do
  include GalaxyTool::Matcher

  before do
    @tool = RSSGenerator.new
  end

  it "PubMedデータ一覧ファイルパス指定として '--pubmed-list-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:pubmed_list, '--pubmed-list-file')
  end

  it "'--pubmed-list-file' オプションを、PMID、タイトル、日付、内容でタブ区切りされたデータが書かれたファイルパスとして受けつける" do
    @tool.should evaluate_option('--pubmed-list-file', stub_file("1234\tTITLE1\t2002-05-30T09:30:10-06:00\tDESCRIPTION1\n1235\tTITLE2\t2002-05-31T09:30:10-06:00\tDESCRIPTION2\n").path, [["1234", "TITLE1", "2002-05-30T09:30:10-06:00", "DESCRIPTION1"], ["1235", "TITLE2", "2002-05-31T09:30:10-06:00", "DESCRIPTION2"]])
  end

  it "PMID、タイトル、日付、内容の4つで構成されているPubMedデータ一覧を受けつける" do
    @tool.should_not reject_option(:pubmed_list, [["1234", "TITLE1", "2002-05-30T09:30:10-06:00", "DESCRIPTION1"], ["1235", "TITLE2", "2002-05-31T09:30:10-06:00", "DESCRIPTION2"]])
  end

  it "PMID、タイトル、日付、内容の4つで構成されていないPubMedデータ一覧は受けつけない" do
    @tool.should reject_option(:pubmed_list, [["hoge", "fuga", "piyo"]])
  end

  it "PubMedデータ一覧ファイルパスの指定は必須である" do
    @tool.should require_option(:pubmed_list)
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

  describe "PubMedデータ一覧ファイルパス、出力先を指定して実行すると" do
    before do
      pubmed_list_file = stub_file("1234\tTITLE1\t2002-05-30T09:30:10-06:00\tDESCRIPTION1\n1235\tTITLE2\t2002-05-31T09:30:10-06:00\tDESCRIPTION2\n")
      @output = stub_file
      @tool.run ["--pubmed-list-file", pubmed_list_file.path, "-o", @output.path]
    end
    
    it "PubMedデータ一覧を元に RSS を出力先に出力する" do
      @output.should be_output(<<-EOT)
<?xml version="1.0" encoding="utf-8" ?>
<rdf:RDF
  xmlns="http://purl.org/rss/1.0/"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <channel rdf:about="http://example.com/rss">
    <items>
      <rdf:Seq>
        <rdf:li rdf:resource="http://www.ncbi.nlm.nih.gov/pubmed/1234"/>
        <rdf:li rdf:resource="http://www.ncbi.nlm.nih.gov/pubmed/1235"/>
      </rdf:Seq>
    </items>
  </channel>
  <item rdf:about="http://www.ncbi.nlm.nih.gov/pubmed/1234">
    <title>TITLE1</title>
    <link>http://www.ncbi.nlm.nih.gov/pubmed/1234</link>
    <description>DESCRIPTION1</description>
    <date>2002-05-30T09:30:10-06:00</date>
  </item>
  <item rdf:about="http://www.ncbi.nlm.nih.gov/pubmed/1235">
    <title>TITLE2</title>
    <link>http://www.ncbi.nlm.nih.gov/pubmed/1235</link>
    <description>DESCRIPTION2</description>
    <date>2002-05-31T09:30:10-06:00</date>
  </item>
</rdf:RDF>
      EOT
    end
  end
end
