DBCLS Galaxy
============
http://galaxy.g.hatena.ne.jp/

DBCLS Galaxyに関する最新の情報はWebサイト上にあります。

概要
====
DBCLS GalaxyはGalaxy(http://g2.bx.psu.edu/)にDBCLS独自のツールを組込んだパッケージです。

Galaxyに関する詳細な情報は http://g2.bx.psu.edu/ をご覧下さい。
DBCLS Galaxy独自の機能に関しては http://lifesciencedb.jp/lsdb.cgi?lng=jp&gg=support までお問い合わせください。

起動方法
========
DBCLS GalaxyはPython 2.4もしくは2.5を必要とします。まずは以下のコマンドを実行して、あなたの環境のPythonのバージョンを確認してください。

% python -V
Python 2.4.4

また、DBCLSツール群を起動するためには、Ruby 1.8.6もしくは1.8.7に加え、Rubygems(gem)及び各種ライブラリが必要となります。

% ruby -v
ruby 1.8.7 (2009-06-12 patchlevel 174) [i686-darwin9]

% gem -v
1.3.5

% gem list
json (1.1.7)
mechanize (0.9.3)
...

上記ツールに関する詳しいことは、各ツールの公式サイトをご覧下さい。

 - Python ... http://www.python.jp/
 - Ruby ... http://www.ruby-lang.org/ja/
 - Rubygems ... http://rubygems.org/

DBCLS Galaxyを起動する前に、まずセットアップスクリプトを実行してください。

% sh setup.sh

環境によっては以下のような警告とともに終了します。

  Your platform (****) is not supported.
  Pre-built galaxy eggs are not available from the Galaxy developers for
  your platform.  You may be able to build them by hand with:
    python scripts/scramble.py

その場合は、その警告に記述されているビルド手順に従い、以下のコマンドを実行します。

% python scripts/scramble.py

上記セットアップが完了したら、以下のコマンドを実行しGalaxyを起動してください。

% sh run.sh

コンソールにログを出力しながらGalaxyが起動を開始します。
以下がコンソールに表示されるまで待って下さい。

    :
    :
  Starting server in PID ****.
  serving on http://127.0.0.1:8080

上記が出力されたら、ブラウザ経由で以下のアドレスにアクセスして下さい。

  http://localhost:8080/

ブラウザ上にGalaxyが表示されれば、DBCLS Galaxyの起動は完了です。

もし、デフォルトの設定を変更したい場合は、universe_wsgi.iniファイルを修正してください。
Galaxy内の各種ツールに関する設定は、tool_conf.xmlを修正してください。
