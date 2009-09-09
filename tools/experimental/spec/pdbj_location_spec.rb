# -*- coding: utf-8 -*-
require File.expand_path('../pdbj_location', File.dirname(__FILE__))

describe PDBjLocationGenerator, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = PDBjLocationGenerator.new
  end

  it "PDB ID リストファイルのパス指定として '--pdb-id-list-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:pdb_id_list, '--pdb-id-list-file')
  end

  it "'--pdb-id-list-file' オプションを、PDB ID 一覧が書かれたファイルのパスとして受けつける" do
    @tool.should evaluate_option('--pdb-id-list-file', stub_file("4HHB\tAAAAAA\tBBBBBBB\n9INS\tAAAAAA\tBBBBBBB\n1MPY\tAAAAAA\tBBBBBBB").path, ["4HHB", "9INS", "1MPY"])
  end

  it "PDB ID リストファイルパスの指定は必須である" do
    @tool.should require_option(:pdb_id_list)
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

  describe "PDB ID リストファイルパス、出力先を指定して実行すると" do
    before do
      pdb_id_list_file = stub_file("4HHB\n9INS\n1MPY")
      @output = stub_file
      @tool.run ["--pdb-id-list-file", pdb_id_list_file.path, "-o", @output.path]
    end
    
    it "PDBj jV への URL へ変換して結果を出力先に出力する" do
      @output.should be_output(<<-EOT)
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=4HHB&PAGEID=Interactive2
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=9INS&PAGEID=Interactive2
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=1MPY&PAGEID=Interactive2
      EOT
    end
  end
end
