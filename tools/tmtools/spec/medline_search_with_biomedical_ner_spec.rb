# -*- coding: utf-8 -*-
require File.expand_path('../medline_search_with_biomedical_ner', File.dirname(__FILE__))

describe MedlineSearchWithBiomedicalNer, "は" do
  include GalaxyTool::Matcher

  before do
    @tool = MedlineSearchWithBiomedicalNer.new
  end

  it "MEDLINEアブストラクト一覧指定として '--medlines-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:medline_abstracts, '--medlines-file')
  end

  it "'--medlines-file' オプションを、id、title/abstract分類、行数、内容でタブ区切りされたデータファイルとして受けつけ、{:id => String, :title => {num_of_lines => content, ... }, :abstract => {num_of_lines => content, ... }形式でパースする" do
    @tool.should evaluate_option('--medlines-file',
                                 stub_file("100\tT\t1\t100Title1\n" +
                                           "200\tT\t1\t200Title1\n" +
                                           "200\tA\t1\t200Abstract1\n" +
                                           "200\tA\t2\t200Abstract2\n" +
                                           "100\tT\t2\t100Title2\n").path,
                                 [
                                  {
                                    :id => '100',
                                    :title => {
                                      '1' => '100Title1',
                                      '2' => '100Title2',
                                    },
                                    :abstract => {},
                                  },
                                  {
                                    :id => '200',
                                    :title => {
                                      '1' => '200Title1',
                                    },
                                    :abstract => { 
                                      '1' => '200Abstract1',
                                      '2' => '200Abstract2',
                                    }
                                  }
                                 ])
  end

  it "MEDLINEアブストラクト一覧指定は必須である" do
    @tool.should require_option(:medline_abstracts)
  end

  it "1行が、Integer、'T' or 'A'、Integer、String、というフォーマットになっていないMEDLINEアブストラクトが渡されたらパースエラーを投げる" do
    proc{ @tool.evaluate_option('--medlines-file', stub_file("string\tT\t1\thoge\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--medlines-file', stub_file("111111\tB\t1\thoge\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--medlines-file', stub_file("111111\tT\tA\thoge\n").path) }.should raise_error(GalaxyTool::ParseError)
  end

  it "NER読込み結果指定として '--ner-results-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:ner_results, '--ner-results-file')
  end

  it "'--ner-results-file' オプションを、id、title/abstract分類、行数、語の分類、語、出現開始文字位置、出現終了文字位置、データベースIDでタブ区切りされたデータファイルとして受けつけ、{:id => String, :title => {num_of_lines => [{:class => String, :term => String, :start => Integer, :end => Integer, :db_id => String }, ... ], ...}, :abstract => {num_of_lines => [{:class => String, :term => String, :start => Integer, :end => Integer, :db_id => String }, ...], ...} }形式でパースする" do
    @tool.should evaluate_option('--ner-results-file',
                                 stub_file("100\tT\t1\tdisease\t100Ti\t0\t5\tUMLS:C111111\n" +
                                           "200\tT\t1\thuman_gene\tTitle\t3\t8\tUMLS:C111112\n" +
                                           "200\tA\t2\thuman_gene\tAbstract2\t3\t11\tUMLS:C111113\n" +
                                           "200\tA\t2\tdisease\t200\t0\t3\tUMLS:C111114\n" +
                                           "200\tA\t1\tdisease\tAbs\t3\t6\tUMLS:C111115\n").path,
                                 [
                                  {
                                    :id => "100",
                                    :title => {
                                      "1" => [
                                              {
                                                :class => "disease",
                                                :term => "100Ti",
                                                :begin => 0,
                                                :end => 5,
                                                :db_id => "UMLS:C111111"
                                              }
                                             ]
                                    },
                                    :abstract => {}
                                  },
                                  {
                                    :id => "200",
                                    :title => {
                                      "1" => [
                                              {
                                                :class => "human_gene",
                                                :term => "Title",
                                                :begin => 3,
                                                :end => 8,
                                                :db_id => "UMLS:C111112"
                                              }
                                             ]
                                    },
                                    :abstract => {
                                      "1" => [
                                              {
                                                :class => "disease",
                                                :term => "Abs",
                                                :begin => 3,
                                                :end => 6,
                                                :db_id => "UMLS:C111115"
                                              }
                                             ],
                                      "2" => [
                                              {
                                                :class => "human_gene",
                                                :term => "Abstract2",
                                                :begin => 3,
                                                :end => 11,
                                                :db_id => "UMLS:C111113"
                                              },
                                              {
                                                :class => "disease",
                                                :term => "200",
                                                :begin => 0,
                                                :end => 3,
                                                :db_id => "UMLS:C111114"
                                              }
                                             ]
                                    }
                                  }
                                 ])
  end

  it "NER読込み結果指定は必須である" do
    @tool.should require_option(:ner_results)
  end

  it "1行が、Integer、'T' or 'A'、Integer, String, String, Integer、Integer、String、というフォーマットになっていないNER読込み結果が渡されたらパースエラーを投げる" do
    proc{ @tool.evaluate_option('--ner-results-file', stub_file("AAA\tT\t1\tdisease\t100Ti\t0\t5\tUMLS:C111111\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--ner-results-file', stub_file("100\tB\t1\tdisease\t100Ti\t0\t5\tUMLS:C111111\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--ner-results-file', stub_file("100\tT\tA\tdisease\t100Ti\t0\t5\tUMLS:C111111\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--ner-results-file', stub_file("100\tT\t1\tdisease\t100Ti\tA\t5\tUMLS:C111111\n").path) }.should raise_error(GalaxyTool::ParseError)
    proc{ @tool.evaluate_option('--ner-results-file', stub_file("100\tT\t1\tdisease\t100Ti\t0\tA\tUMLS:C111111\n").path) }.should raise_error(GalaxyTool::ParseError)
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

  describe "MEDLINEアブストラクト一覧、NER読込み結果、出力先を指定してコマンドを実行すると" do
    before do
      @medline_abstracts_file = stub_file("100\tT\t1\t100Title1\n" +
                                          "200\tT\t1\t200Title1\n" +
                                          "200\tA\t1\t200Abstract1\n" +
                                          "200\tA\t2\t200Abstract2\n" +
                                          "100\tT\t2\t100Title2\n")
      @ner_results_file = stub_file("100\tT\t1\tdisease\t100Ti\t0\t5\tUMLS:C111111\n" +
                                    "200\tT\t1\thuman_gene\tTitle\t3\t8\tUMLS:C111112\n" +
                                    "200\tA\t2\thuman_gene\tAbstract2\t3\t11\tUMLS:C111113\n" +
                                    "200\tA\t2\tdisease\t200\t0\t3\tUMLS:C111114\n" +
                                    "200\tA\t1\tdisease\tAbs\t3\t6\tUMLS:C111115\n")
      @output = stub_file
      @tool.run ["--medlines-file", @medline_abstracts_file.path, "--ner-results-file", @ner_results_file.path, "-o", @output.path]
    end

    it "MEDLINEアブストラクト一覧、NER読込み結果を元にバイオメディカル関連語の強調してMEDLINE タイトル/アブストラクトを出力する" do
      @output.should be_output(<<-EOT)
PMID:
  100
Title:
  [[100Ti<disease>]]tle1
  100Title2
Abstract:

PMID:
  200
Title:
  200[[Title<human_gene>]]1
Abstract:
  200[[Abs<disease>]]tract1
  [[200<disease>]][[Abstract<human_gene>]]2

      EOT
    end
  end  
end
