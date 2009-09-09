# -*- coding: utf-8 -*-
require File.expand_path('../pne_search', File.dirname(__FILE__))

describe PNESearch, "は" do
  include GalaxyTool::Matcher
  
  before do
    @tool = PNESearch.new
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
      @tool.should_receive(:search).with("遺伝子").and_return('{"info":{"hit":"1634","query":"http:\/\/lifesciencedb.jp\/pne\/?phrase=%E9%81%BA%E4%BC%9D%E5%AD%90&outputStyle=JSON&titleLength=0"},"result":[{"db":"pne","score":"11680","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u30d2\u30b9\u30c8\u30f3\u907a\u4f1d\u5b50 : \u69cb\u9020\u3068\u8ee2\u5199\u8abf\u7bc0","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1985&number=3005&file=YVPLUShWjrPLUSeOEVAoB\/XHEFmA==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 30 5 1985 374-383 \u7dcf\u8aac \u30d2\u30b9\u30c8\u30f3\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n : \u69cb\u9020\u3068\u8ee2\u5199\u8abf\u7bc0 Histone Genes-Structure an\n\ny, Faculty of Science, Hokkaido University \u30d2\u30b9\u30c8\u30f3\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u7814\u7a76\u306f, \u30a6\u30cb\u3084\u30b7\u30e7\u30a6\u30b8\u30e7\u30a6\u30d0\u30a8\u306b\u304a\u3044\u3066\u59cb\u3081\u3089\u308c, \u30b2\n\n\u30ce\u30e0\u5185\u3067\u591a\u91cd\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u3068\u3057\u3066\u5b58\u5728\u3059\u308b\u3053\u3068\u304c\u793a\u3055\u308c\u305f\u3002\u305d\u306e\u5f8c, \u4ed6\u306e\u751f\u7269\u306e\u30d2\u30b9\n\n\u30c8\u30f3\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u7814\u7a76\u3082\u9032\u3080\u306b\u3064\u308c\u3066, \u3053\u306e\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u7de8\u6210\u30d1\u30bf\u30fc\u30f3\u306b\u591a\u69d8\n\n\u6027\u306e\u3042\u308b\u3053\u3068\u304c\u660e\u3089\u304b\u306b\u306a\u3063\u305f\u3002\u30d2\u30b9\u30c8\u30f3\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306f\u771f\u6838\u751f\u7269\u306b\u666e\u904d\u7684\u306b\u5b58\u5728\u3057, \u305d\u306e\u4e00\u6b21\u69cb\u9020\u3082\u751f\u7269\u9593\u3067\u6bd4\n\n"}, {"db":"pne","score":"11318","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u6838\u5185\u764c\u907a\u4f1d\u5b50\u7523\u7269\u306b\u3088\u308b\u7d30\u80de\u907a\u4f1d\u5b50\u306e\u8ee2\u5199\u8abf\u7bc0","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1987&number=3207&file=SxmKDFQdu6Lc9Ff4u5ZYsQ==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 32 7 1987 943-954 \u7dcf\u8aac \u6838\u5185\u764c\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u7523\u7269\u306b\u3088\u308b\u7d30\u80de\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u8ee2\u5199\u8abf\u7bc0 Transcriptional\n\nto University Medical School \u6700\u8fd1, \u3044\u304f\u3064\u304b\u306e\u6838\u5185\u764c\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306b\u3064\u3044\u3066, \u305d\u306e\u7523\u7269\u304c\u7d30\u80de\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u8ee2\u5199\u3092\u6d3b\u6027\u5316\u3055\u305b\u308b\u8ee2\n\ns-activation \u6d3b\u6027) \u3092\u6709\u3057\u3066\u3044\u308b\u3053\u3068\u304c\u660e\u3089\u304b\u306b\u3055\u308c, \n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u7570\u5e38\u767a\u73fe\u3068\u764c\u5316\u3068\u306e\u95a2\u9023\u3092\u8abf\u3079\u308b\u3046\u3048\u3067\u3068\u304f\u306b\u6ce8\u76ee\u3055\u308c\n\n\u3066\u3044\u308b\u3002\u7b46\u8005\u3089\u306f, \u30de\u30a6\u30b9\u9aa8\u8089\u816b\u30a6\u30a4\u30eb\u30b9\u306e\u764c\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n v-fos \u306e\u7523\u7269\u304c, III\u578b\u03b1_1\u30b3\u30e9\u30fc\u30b2\u30f3\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u304a\u3088\u3073\u30e9\u30a6\n\n\u307f\u305f\u3002\u672c\u7a3f\u3067\u306f, \u7b46\u8005\u3089\u306e\u7814\u7a76\u6210\u679c\u3092\u7d39\u4ecb\u3057, \u4ed6\u306e\u6838\u5185\u764c\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u7523\u7269\u306b\u3064\u3044\u3066\u306e\u77e5\u898b\u306b\u3082\u89e6\u308c\u306a\u304c\u3089, \u8ee2\u5199\u4fc3\u9032\u6d3b\u6027\u3068\u764c\u5316\n\n"},{"db":"pne","score":"11205","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u690d\u7269\u306e\u8ee2\u79fb\u56e0\u5b50\u3068\u30c8\u30e9\u30f3\u30b9\u30dd\u30be\u30f3\u30bf\u30ae\u30f3\u30b0","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1992&number=3704&file=t6ie2D5Igfnh2J6puxL1Og==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 37 4 1992 695-709 \u7dcf\u8aac \u690d\u7269\u306e\u8ee2\u79fb\u56e0\u5b50\u3068\u30c8\u30e9\u30f3\u30b9\u30dd\u30be\u30f3\u30bf\u30ae\u30f3\u30b0 Plant Transposable \n\n Research Institute, Kamoshida \u5f93\u6765, \u52d5\u690d\u7269\u306e\u591a\u304f\u306e\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306f\u305d\u306e\u7523\u7269\u306e\u6027\u8cea\u3084\u767a\u73fe\u69d8\u5f0f\u3092\u57fa\u306b\u5206\u96e2\u3055\u308c\u3066\u3044\u308b\u3002\u4e00\u65b9\n\n, \u8ee2\u79fb\u56e0\u5b50\u3092\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u5185\u306b\u8ee2\u79fb\u3055\u305b\u3066, \u633f\u5165\u7a81\u7136\u5909\u7570\u4f53\u3092\u4f5c\u51fa\u3057, \u8ee2\u79fb\u56e0\u5b50\u3092\u30d7\n\n\u30ed\u30fc\u30d6\u3068\u3057\u3066\u56e0\u5b50\u306e\u633f\u5165\u3055\u308c\u3066\u3044\u308b\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u3092\u540c\u5b9a\u30fb\u5206\u96e2\u3057\u3088\u3046\u3068\u3059\u308b\u30c8\u30e9\u30f3\u30b9\u30dd\u30be\u30f3\u30bf\u30ae\u30f3\u30b0\u6cd5\u306f, \n\n\u7523\u7269\u306b\u95a2\u3059\u308b\u77e5\u898b\u306e\u306a\u3044\n<strong class=\"key1\">\u907a\u4f1d\u5b50<\/strong>\n\u306e\u5206\u96e2\u6cd5\u3068\u3057\u3066\u6ce8\u76ee\u3055\u308c, \u690d\u7269\u306b\u304a\u3044\u3066\u3082\u30c8\u30a6\u30e2\u30ed\u30b3\u30b7\u3084\n\n"}]}')
      
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-q", "遺伝子", "-o", @output.path]
    end
  
    it " PNE 検索を行い、タイトル・URLの組をタブ区切りで1行づつ検索結果を出力先に出力する" do
      @output.should be_output(<<-EOT)
蛋白質核酸酵素:ヒストン遺伝子 : 構造と転写調節	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1985&number=3005&file=YVPLUShWjrPLUSeOEVAoB/XHEFmA==
蛋白質核酸酵素:核内癌遺伝子産物による細胞遺伝子の転写調節	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1987&number=3207&file=SxmKDFQdu6Lc9Ff4u5ZYsQ==
蛋白質核酸酵素:植物の転移因子とトランスポゾンタギング	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1992&number=3704&file=t6ie2D5Igfnh2J6puxL1Og==
      EOT
    end

    it "規定値のInfo出力先である標準出力にクエリに関する情報を出力する" do
      @info.should be_output("Searching PNE with query = '遺伝子'\n")
    end
  end

  describe "結果が存在しないクエリを指定して実行すると" do
    before do
      @tool.should_receive(:search).with("結果無しクエリ").and_return('{"info":{"hit":"0","query":"http:\/\/lifesciencedb.jp\/pne\/?phrase=%E7%B5%90%E6%9E%9C%E3%81%AE%E7%84%A1%E3%81%84%E3%82%AF%E3%82%A8%E3%83%AA&outputStyle=JSON&titleLength=0"},"result":null}')
      
      @output = stub_file
      @info = stub_stdout
      @tool.run ["-q", "結果無しクエリ", "-o", @output.path]
    end
  
    it "なにも出力しない" do
      @output.should be_output('')
    end
  end
end
