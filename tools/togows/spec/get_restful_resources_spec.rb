# -*- coding: utf-8 -*-
require File.expand_path('../get_restful_resources', File.dirname(__FILE__))
require 'net/http'

describe GetRestfulResources, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = GetRestfulResources.new
  end

  it "エントリーIDファイルパスの指定として '-e' オプションを受けつける" do
    @tool.should accept_option_with_argument(:entry_ids, '-e')
  end

  it "エントリーIDファイルパスの指定として '--entry-id-file' オプションを受けつける" do
    @tool.should accept_option_with_argument(:entry_ids, '--entry-id-file')
  end

  it "'--entry-id-file' オプションを、エントリーIDの一覧が書かれたファイルパスとして受けつける" do
    @tool.should evaluate_option('--entry-id-file', stub_file("123456\n123457\n123458\n").path, ["123456", "123457", "123458"])
  end

  it "エントリーIDファイルパスの指定は必須である" do
    @tool.should require_option(:entry_ids)
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

  it "フィールド指定として '-f' オプションを受けつける" do
    @tool.should accept_option_with_argument(:field, '-f')
  end

  it "フィールド指定として '--field' オプションを受けつける" do
    @tool.should accept_option_with_argument(:field, '--field')
  end

  it "フィールド指定は必須である" do
    @tool.should require_option(:field)
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

  describe "データベース名、エントリーID一覧、フィールド、出力先を指定して実行すると" do
    before do
      @tool.should_receive(:get_resources).with("pubmed", ["123456", "123457", "123458"], "title").and_return('["[The laboratory in programs for enteric infection control]","[Attention of the hospital in health services and in the community towards the control of intestinal diseases]","[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]"]')

      entry_id_file = stub_file("123456\n123457\n123458\n")
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-e", entry_id_file.path, "-d", "pubmed", "-f", "title", "-o", @output.path]
    end
    
    it " TogoWS エントリーフィールド値取得を行いIDとフィールド値をタブで区切って1行づつ検索結果を出力先に出力する" do
      @output.should be_output("123456\t[The laboratory in programs for enteric infection control]\n123457\t[Attention of the hospital in health services and in the community towards the control of intestinal diseases]\n123458\t[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]\n")
    end

    it "規定値のInfo出力先である標準出力にデータベース名やクエリに関する情報を出力する" do
      @info.should be_output("Getting TogoWS entry resource with database = 'pubmed', field = 'title'\n")
    end

  end
  
  describe " データ取得方法として" do
    it " 一括取得を行うことができる" do
      @tool = GetRestfulResources.new
      @http = MockHttp.new
      @tool.http = @http

      @entry_id_file = stub_file("123456\n123457\n123458\n")
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-e", @entry_id_file.path, "-d", "pubmed", "-f", "title", "-o", @output.path]

      @output.should be_output("123456\t[The laboratory in programs for enteric infection control]\n123457\t[Attention of the hospital in health services and in the community towards the control of intestinal diseases]\n123458\t[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]\n")

      # getが呼ばれる回数は1回
      @http.number_of_calling.should == 1
    end

    it " 一括取得が不可能な場合は個別取得を行うことができる" do
      @tool = GetRestfulResources.new
      @http = MockHttpRaisesBadGatewayError.new
      @tool.http = @http

      @entry_id_file = stub_file("123456\n123457\n123458\n")
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-e", @entry_id_file.path, "-d", "pubmed", "-f", "title", "-o", @output.path]

      @output.should be_output("123456\t[The laboratory in programs for enteric infection control]\n123457\t[Attention of the hospital in health services and in the community towards the control of intestinal diseases]\n123458\t[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]\n")

      # getが呼ばれる回数は「一括取得1回、個別取得3回」の計4回
      @http.number_of_calling.should == 4
    end
  end

  describe " Httpオブジェクトを指定可能にした場合" do
    it " Httpオブジェクトを指定しなくてもデータを取得することができる" do
      @tool = GetRestfulResources.new

      @entry_id_file = stub_file("123456\n123457\n123458\n")
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-e", @entry_id_file.path, "-d", "pubmed", "-f", "title", "-o", @output.path]

      @output.should be_output("123456\t[The laboratory in programs for enteric infection control]\n123457\t[Attention of the hospital in health services and in the community towards the control of intestinal diseases]\n123458\t[Importance of environmental sanitation in urban and rural areas for the control of intestinal infections]\n")
    end
  end

  describe "JSON オブジェクトが要素として返ってくるようなフィールドを指定して実行すると" do
    before do
      @tool.should_receive(:get_resources).with("kegg-genes", ["hsa:9540", "hsa:9541"], "motif").and_return('[{"Pfam":["ADH_N","ADH_zinc_N"]},{"Pfam":["Cir_N","Dehydrin","zf-CCHC","DUF1168","DUF755"],"PROSITE":["LYS_RICH","SER_RICH","NLS_BP"]}]')
      
      entry_id_file = stub_file("hsa:9540\nhsa:9541\n")
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-e", entry_id_file.path, "-d", "kegg-genes", "-f", "motif", "-o", @output.path]
    end
    
    it "JSON オブジェクトをプロパティ名とプロパティ値に分解しタブ区切りにし、プロパティ毎に1行づつ出力先IOに出力する" do
      @output.should be_output(<<-EOT)
hsa:9540	Pfam	ADH_N
hsa:9540	Pfam	ADH_zinc_N
hsa:9541	Pfam	Cir_N
hsa:9541	Pfam	Dehydrin
hsa:9541	Pfam	zf-CCHC
hsa:9541	Pfam	DUF1168
hsa:9541	Pfam	DUF755
hsa:9541	PROSITE	LYS_RICH
hsa:9541	PROSITE	SER_RICH
hsa:9541	PROSITE	NLS_BP
        EOT
    end
  end
end


class MockHttp < Http
  def initialize(&block)
    @n = 0
    @block = block
  end

  def number_of_calling
    @n
  end

  def get(host, path)
    @n = @n + 1
    Net::HTTP.version_1_2
    Net::HTTP.start(host, 80) {|http|
      response = http.get(path)
      response.body
    }
  end
end

class MockHttpRaisesBadGatewayError < Http
  def initialize(&block)
    @n = 0
    @block = block
  end

  def number_of_calling
    @n
  end

  def get(host, path)
    # 最初の呼び出し時にのみBadGatewayErrorを発生させる
    if @n == 0
      @n = @n + 1
      raise BadGatewayError
    else
      @n = @n + 1
      Net::HTTP.version_1_2
      Net::HTTP.start(host, 80) {|http|
        response = http.get(path)
        response.body
      }
    end
  end
end

describe "Httpクラスは" do
  it " 502 BadGateway が返ってきた場合に BadGatewayError を発生させる" do
    http = Http.new
    host = 'togows.dbcls.jp'

    # BadGatewayErrorが発生すること
    path = '/entry/ncbi-pubmed/19569254,19569244,19569240,19569239,19569236,19569235,19569230,19569224,19569220,19569217,19569214,19569206,19569180,19569179,19569085,19569082,19569075,19569061,19569050,19569049,19569045,19569044,19569017,19569011,19569000,19568996,19568977,19568952,19568949,19568851,19568827,19568805,19568804,19568771,19568767,19568762,19568750,19568747,19568743,19568730,19568691,19568645,19568611,19568591,19568590,19568552,19568456,19568434,19568427,19568426,19568425,19568423,19568420,19568415,19568411,19568409,19568339,19568323,19568272,19568270,19568269,19568241,19568224,19568223,19568222,19568221,19568185,19568049,19568046,19567998,19567987,19567894,19567893,19567881,19567877,19567870,19567835,19567831,19567823,19567819,19567787,19567785,19567780,19567738,19567707,19567677,19567676,19567670,19567627,19567588,19567587,19567585,19567584,19567582,19567581,19567580,19567578,19567577,19567576,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575,19567575/title.json'
    lambda { http.get(host, path) }.should raise_error(BadGatewayError)

    # BadGatewayErrorが発生しないこと
    path = '/entry/ncbi-pubmed/19569254/title.json'
    lambda { http.get(host, path) }.should_not raise_error(BadGatewayError)
  end
end

