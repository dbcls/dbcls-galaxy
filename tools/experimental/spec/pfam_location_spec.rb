# -*- coding: utf-8 -*-
require File.expand_path('../pfam_location', File.dirname(__FILE__))

describe PfamLocationGenerator, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = PfamLocationGenerator.new
  end

  it "Pfam IDリストファイルのパス指定として '--pfam-id-list-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:pfam_id_list, '--pfam-id-list-file')
  end

  it "'--pfam-id-list-file' オプションを、Pfam ID一覧が書かれたファイルのパスとして受けつける" do
    @tool.should evaluate_option('--pfam-id-list-file', stub_file("YrbL-PhoP_reg\tAAAAAA\tBBBBBBB\nDpy-30\tAAAAAA\tBBBBBBB\nRIIa\tAAAAAA\tBBBBBBB").path, ["YrbL-PhoP_reg", "Dpy-30", "RIIa"])
  end

  it "Pfam IDリストファイルパスの指定は必須である" do
    @tool.should require_option(:pfam_id_list)
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

  describe "Pfam IDリストファイルパス、出力先を指定して実行すると" do
    before do
      pfam_id_list_file = stub_file("YrbL-PhoP_reg\nDpy-30\nRIIa")
      @output = stub_file
      @tool.run ["--pfam-id-list-file", pfam_id_list_file.path, "-o", @output.path]
    end
    
    it "Pfam への URL へ変換して結果を出力先に出力する" do
      @output.should be_output(<<-EOT)
http://pfam.sanger.ac.uk/family?entry=YrbL-PhoP_reg
http://pfam.sanger.ac.uk/family?entry=Dpy-30
http://pfam.sanger.ac.uk/family?entry=RIIa
      EOT
    end
  end
end
