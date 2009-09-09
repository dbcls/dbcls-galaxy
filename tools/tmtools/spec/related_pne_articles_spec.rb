# -*- coding: utf-8 -*-
require File.expand_path('../related_pne_articles', File.dirname(__FILE__))

describe RelatedPNEArticles, "は" do
  include GalaxyTool::Matcher

  before do
    @tool = RelatedPNEArticles.new
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

  describe "MEDLINE search 結果を指定して make_pmid_file を実行すると" do
    before do
      @medlines = <<-EOT
16547464	Maintaining genome integrity.
9841419	A genome sampler.
9019811	Human genome agreements.
      EOT
      @filepath = @tool.make_pmid_file(@medlines)
    end

    it "MEDLINE search 結果の ID のみが記載されたファイルを生成する" do
      File.read(@filepath).should == <<-EOT
16547464
9841419
9019811
        EOT
    end
  end

  describe "make_control_tables_output を実行すると" do
    before do
      @path = @tool.make_control_tables_output
    end

    it "中身が空のファイルを生成する" do
      File.read(@path).should == ""
    end
  end

  describe "PMID 一覧のパスと出力先を指定して control_tables_command を実行すると" do
    it "実行するコマンド文字列を生成する" do
      @tool.control_tables_command('/path/to/pmid_list', '/path/to/output').should == "sh /opt/services/galaxy/related_pne/src/customized_control_tables/control_table.sh t2 '/path/to/pmid_list' '/path/to/output' /opt/services/galaxy/related_pne/src/customized_control_tables"
    end
  end

  describe "MEDLINE search結果を指定して transrate_to_japanese が実行されたら" do
    before do
      @medlines = <<-EOT
16547464	Maintaining genome integrity.
9841419	A genome sampler.
9019811	Human genome agreements.
      EOT

      @tool.should_receive(:control_tables).and_return do |pmid_path, japanese_query_results_path|
        File.read(pmid_path).should == <<-EOT
16547464
9841419
9019811
        EOT
        File.open(japanese_query_results_path, 'a') do |f|
          f.print <<-EOT
9841419	A|	A
1316123	in|	類似の
153200	mitochondrial|yeast|	ミトコンドリアの|酵母
          EOT
        end

        @pmid_path = pmid_path
        @japanese_query_results_path = japanese_query_results_path
      end

      @result = @tool.transrate_to_japanese(@medlines)
    end

    it "日本語クエリを含む ControlTableRecord を一覧で返す" do
      @result.should ==
        [
         RelatedPNEArticles::ControlTableRecord.new("9841419", "A|", "A"),
         RelatedPNEArticles::ControlTableRecord.new("1316123", "in|", "類似の"),
         RelatedPNEArticles::ControlTableRecord.new("153200", "mitochondrial|yeast|", "ミトコンドリアの|酵母")
        ]
    end

    it "control_tables 用の一時ファイルは削除する" do
      File.exists?(@pmid_path).should == false
      File.exists?(@japanese_query_results_path).should == false
    end
  end

  describe "ControlTableRecord と出力先を指定して related_pne_article を実行したら" do
    before do
      @tool.should_receive(:search_title).with("1316123").and_return("A genome sampler.");
      @tool.should_receive(:search_pne).with("類似の").and_return('{"info":{"hit":"342","query":"http:\/\/lifesciencedb.jp\/pne\/?phrase=%E9%A1%9E%E4%BC%BC%E3%81%AE&outputStyle=JSON"},"result":[{"db":"pne","score":"15487","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u53e4\u7d30\u83cc Archaebacteria \u306e\u30ea\u30dc\u30bd","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1990&number=3502&file=E8kEYyZCQ\/WbPLUSUWAXLVEJw==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 35 2 1990 130-140 \u7dcf\u8aac \u53e4\u7d30\u83cc Archaebacteria \u306e\u30ea\u30dc\u30bd\u30fc\u30e0 The Archaebacterial Rib\n\n\u76f8\u540c\u6027\u3092\u898b\u3044\u3060\u305b\u306a\u304f\u306a\u3063\u305f\u306e\u304b, \u307e\u305f\u306f\u307e\u3063\u305f\u304f\u72ec\u7acb\u306b\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u914d\u5217\u90e8\u5206\u306b\u53ce\u6582\u9032\u5316\u3057\u305f\u53ef\u80fd\u6027\u304c\u8003\u3048\u3089\u308c\u308b\u3002(ii) \u306e\u771f\u6838\n\n"},{"db":"pne","score":"14142","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u30d7\u30ed\u30c6\u30a4\u30f3\u30dc\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1997&number=4205&file=EBM\/2m9k33YX7gzARPoC\/g==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 42 5 1997 736-743 \u7279\u96c6 \u30d7\u30ed\u30c6\u30a4\u30f3\u30dc\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u3068\u690d\u7269\u7d30\u80de\u5185\u30b7\u30b0\u30ca\u30eb\u4f1d\u9054(\u690d\u7269\u306e\u7d30\u80de\n\n\u305f\u3002 \u690d\u7269\u306e\u7d30\u80de\u5185\u30b7\u30b0\u30ca\u30eb\u4f1d\u9054\u7cfb\u306b\u304a\u3044\u3066\u3082\u591a\u304f\u306e\u5834\u5408,\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u30d7\u30ed\u30c6\u30a4\u30f3\u30ad\u30ca\u30fc\u30bc\u304a\u3088\u3073\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u304c\u95a2\n\n\u3066\u306f\u3088\u304f\u77e5\u3089\u308c\u305f\u54fa\u4e73\u52d5\u7269\u306e\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u3068\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u751f\u5316\u5b66\u7684\u6027\u8cea\u3092\u793a\u3059\u3002\u3044\u304f\u3064\u304b\u306e\u690d\u7269\u306e\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\n\n\u6210\u9175\u7d20)\u306e\u8131\u30ea\u30f3\u9178\u5316\u53cd\u5fdc\u306f\u3067\u304d\u306a\u3044\u3053\u3068\u3092\u793a\u5506\u3057\u3066\u3044\u308b\u3002\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u89b3\u5bdf\u306f,\u5206\u88c2\u9175\u6bcddis2-11\u3092\u7528\u3044\u305f\u76f8\u88dc\u6027\u30c6\u30b9\u30c8\u306a\u3069\u3067\u3082\u306a\n\n\u5236\u5fa1\u30b5\u30d6\u30e6\u30cb\u30c3\u30c8\u306e\u30af\u30ed\u30fc\u30f3\u304c\u5358\u96e2\u3055\u308c\u3066\u304a\u308a,\u30de\u30e1\u304b\u3089\u3082\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u30af\u30ed\u30fc\u30f3\u304c\u5f97\u3089\u308c\u3066\u3044\u308b^\u3002\u690d\u7269\u306eA\u30b5\u30d6\u30e6\u30cb\u30c3\u30c8\u306f\u30d2\u30c8\u306e\n\n"}]}')
      
      @record = RelatedPNEArticles::ControlTableRecord.new("1316123", "in|", "類似の")
      @output = StringIO.new
      @tool.related_pne_article(@record, @output)
    end

    it "PNE検索結果毎に ControlTableRecord の PMID・タイトル、PNE検索結果のタイトル・URL を出力する" do
      @output.should be_output(<<-EOT)
1316123	A genome sampler.	蛋白質核酸酵素:古細菌 Archaebacteria のリボソ	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1990&number=3502&file=E8kEYyZCQ/WbPLUSUWAXLVEJw==
1316123	A genome sampler.	蛋白質核酸酵素:プロテインボスファターゼ	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1997&number=4205&file=EBM/2m9k33YX7gzARPoC/g==
      EOT
    end
  end

  describe "related_pne_article 実行時に PNE検索APIで結果を取得できなかったら" do
    before do
      @tool.should_receive(:search_title).with("999999").and_return("A genome sampler.");
      @tool.should_receive(:search_pne).with("結果無しクエリ").and_return('{"info":{"hit":"0","query":"http:\/\/lifesciencedb.jp\/pne\/?phrase=%E7%B5%90%E6%9E%9C%E3%81%AE%E7%84%A1%E3%81%84%E3%82%AF%E3%82%A8%E3%83%AA&outputStyle=JSON&titleLength=0"},"result":null}')
      
      @record = RelatedPNEArticles::ControlTableRecord.new("999999", "in|", "結果無しクエリ")
      @output = StringIO.new
      @tool.related_pne_article(@record, @output)
    end

    it "なにも出力しない" do
      @output.should be_output(<<-EOT)
      EOT
    end
  end

  describe "クエリ、出力先を指定してコマンドを実行すると" do
    before do
      @tool.should_receive(:control_tables).and_return do |pmid_path, japanese_query_results_path|
        File.open(japanese_query_results_path, 'a') do |f|
          f.print <<-EOT
1316123	in|	類似の
          EOT
        end
      end
      @tool.should_receive(:search_title).with("1316123").and_return("A genome sampler.");
      @tool.should_receive(:search_pne).with("類似の").and_return('{"info":{"hit":"342","query":"http:\/\/lifesciencedb.jp\/pne\/?phrase=%E9%A1%9E%E4%BC%BC%E3%81%AE&outputStyle=JSON"},"result":[{"db":"pne","score":"15487","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u53e4\u7d30\u83cc Archaebacteria \u306e\u30ea\u30dc\u30bd","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1990&number=3502&file=E8kEYyZCQ\/WbPLUSUWAXLVEJw==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 35 2 1990 130-140 \u7dcf\u8aac \u53e4\u7d30\u83cc Archaebacteria \u306e\u30ea\u30dc\u30bd\u30fc\u30e0 The Archaebacterial Rib\n\n\u76f8\u540c\u6027\u3092\u898b\u3044\u3060\u305b\u306a\u304f\u306a\u3063\u305f\u306e\u304b, \u307e\u305f\u306f\u307e\u3063\u305f\u304f\u72ec\u7acb\u306b\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u914d\u5217\u90e8\u5206\u306b\u53ce\u6582\u9032\u5316\u3057\u305f\u53ef\u80fd\u6027\u304c\u8003\u3048\u3089\u308c\u308b\u3002(ii) \u306e\u771f\u6838\n\n"},{"db":"pne","score":"14142","title":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20:\u30d7\u30ed\u30c6\u30a4\u30f3\u30dc\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc","url":"http:\/\/lifesciencedb.jp\/dbsearch\/Literature\/get_pne_cgpdf.php?year=1997&number=4205&file=EBM\/2m9k33YX7gzARPoC\/g==","doc":"\u86cb\u767d\u8cea\u6838\u9178\u9175\u7d20 42 5 1997 736-743 \u7279\u96c6 \u30d7\u30ed\u30c6\u30a4\u30f3\u30dc\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u3068\u690d\u7269\u7d30\u80de\u5185\u30b7\u30b0\u30ca\u30eb\u4f1d\u9054(\u690d\u7269\u306e\u7d30\u80de\n\n\u305f\u3002 \u690d\u7269\u306e\u7d30\u80de\u5185\u30b7\u30b0\u30ca\u30eb\u4f1d\u9054\u7cfb\u306b\u304a\u3044\u3066\u3082\u591a\u304f\u306e\u5834\u5408,\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u30d7\u30ed\u30c6\u30a4\u30f3\u30ad\u30ca\u30fc\u30bc\u304a\u3088\u3073\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u304c\u95a2\n\n\u3066\u306f\u3088\u304f\u77e5\u3089\u308c\u305f\u54fa\u4e73\u52d5\u7269\u306e\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\u30a1\u30bf\u30fc\u30bc\u3068\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u751f\u5316\u5b66\u7684\u6027\u8cea\u3092\u793a\u3059\u3002\u3044\u304f\u3064\u304b\u306e\u690d\u7269\u306e\u30d7\u30ed\u30c6\u30a4\u30f3\u30db\u30b9\u30d5\n\n\u6210\u9175\u7d20)\u306e\u8131\u30ea\u30f3\u9178\u5316\u53cd\u5fdc\u306f\u3067\u304d\u306a\u3044\u3053\u3068\u3092\u793a\u5506\u3057\u3066\u3044\u308b\u3002\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u89b3\u5bdf\u306f,\u5206\u88c2\u9175\u6bcddis2-11\u3092\u7528\u3044\u305f\u76f8\u88dc\u6027\u30c6\u30b9\u30c8\u306a\u3069\u3067\u3082\u306a\n\n\u5236\u5fa1\u30b5\u30d6\u30e6\u30cb\u30c3\u30c8\u306e\u30af\u30ed\u30fc\u30f3\u304c\u5358\u96e2\u3055\u308c\u3066\u304a\u308a,\u30de\u30e1\u304b\u3089\u3082\n<strong class=\"key1\">\u985e\u4f3c\u306e<\/strong>\n\u30af\u30ed\u30fc\u30f3\u304c\u5f97\u3089\u308c\u3066\u3044\u308b^\u3002\u690d\u7269\u306eA\u30b5\u30d6\u30e6\u30cb\u30c3\u30c8\u306f\u30d2\u30c8\u306e\n\n"}]}')
      
      @query_file = stub_file <<-EOT
16547464	Maintaining genome integrity.
9841419	A genome sampler.
9019811	Human genome agreements.
      EOT
      @info = stub_stdout      
      @output = stub_file
      @tool.run ["--query-file", @query_file.path, "-o", @output.path]
    end

    it "ControlTableで日本語クエリ変換後、PNE検索を行い、PNE検索結果毎に ControlTableRecord の PMID・タイトル、PNE検索結果のタイトル・URL を出力する" do
      @output.should be_output(<<-EOT)
1316123	A genome sampler.	蛋白質核酸酵素:古細菌 Archaebacteria のリボソ	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1990&number=3502&file=E8kEYyZCQ/WbPLUSUWAXLVEJw==
1316123	A genome sampler.	蛋白質核酸酵素:プロテインボスファターゼ	http://lifesciencedb.jp/dbsearch/Literature/get_pne_cgpdf.php?year=1997&number=4205&file=EBM/2m9k33YX7gzARPoC/g==
      EOT
    end
  end

  describe "結果が存在しないクエリを指定してコマンドを実行すると" do
    before do
      @tool.should_receive(:control_tables).and_return do |pmid_path, japanese_query_results_path|
        File.open(japanese_query_results_path, 'a') do |f|
          f.print <<-EOT
          EOT
        end
      end
      
      @query_file = stub_file <<-EOT
9999999	has no results. 
      EOT
      @info = stub_stdout      
      @output = stub_file
      @tool.run ["--query-file", @query_file.path, "-o", @output.path]
    end

    it "なにも出力しない" do
      @output.should be_output('')
    end
  end  
end
