# -*- coding: utf-8 -*-
require File.expand_path('../pubmed_get_resource', File.dirname(__FILE__))

describe PubMedGetResource, "は" do
  include GalaxyTool::Matcher
  
  subject { PubMedGetResource.new }

  it "エントリーIDファイルパスの指定として '-e' オプションを受けつける" do
    should accept_option_with_argument(:entry_ids, '-e')
  end

  it "エントリーIDファイルパスの指定として '--entry-id-file' オプションを受けつける" do
    should accept_option_with_argument(:entry_ids, '--entry-id-file')
  end

  it "'--entry-id-file' オプションを、エントリーIDの一覧が書かれたファイルパスとして受けつける" do
    should evaluate_option('--entry-id-file', stub_file("123456\n123457\n123458\n").path, ["123456", "123457", "123458"])
  end

  it "エントリーIDファイルパスの指定は必須である" do
    should require_option(:entry_ids)
  end

  it "フィールド指定として '-f' オプションを受けつける" do
    should accept_option_with_argument(:field, '-f')
  end

  it "フィールド指定として '--field' オプションを受けつける" do
    should accept_option_with_argument(:field, '--field')
  end

  it "フィールド指定は必須である" do
    should require_option(:field)
  end

  it "出力先指定として '-o' オプションを受けつける" do
    should accept_option_with_argument(:output, '-o')
  end

  it "出力先指定として '--output' オプションを受けつける" do
    should accept_option_with_argument(:output, '--output')
  end

  it "出力先指定は必須である" do
    should require_option(:output)
  end

  it "Info出力先指定として '--info' オプションを受けつける" do
    should accept_option_with_argument(:info, '--info')
  end

  it "Info出力先の規定値は標準出力である" do
    should set_default_option_value(:info, '/dev/stdout')
  end

  describe "データベース名、エントリーID一覧、フィールド、出力先を指定して実行すると" do
    before do
      subject.should_receive(:get_resources).with("ncbi-pubmed", ["123456", "123457", "123458"], "title").and_return('["[The laboratory in programs for enteric infection control]","[Attention of the hospital in health services and in the community towards the control of intestinal diseases]","[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]"]')

      entry_id_file = stub_file("123456\n123457\n123458\n")
      @output = stub_file
      @info = stub_stdout
      subject.run ["-e", entry_id_file.path, "-f", "title", "-o", @output.path]
    end
    
    it " TogoWS エントリーフィールド値取得を行いIDとフィールド値をタブで区切って1行づつ検索結果を出力先に出力する" do
      @output.should be_output("123456\t[The laboratory in programs for enteric infection control]\n123457\t[Attention of the hospital in health services and in the community towards the control of intestinal diseases]\n123458\t[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]\n")
    end

    it "規定値のInfo出力先である標準出力にデータベース名やクエリに関する情報を出力する" do
      @info.should be_output("Getting PubMed entry resource with field = 'title'\n")
    end
  end
end
