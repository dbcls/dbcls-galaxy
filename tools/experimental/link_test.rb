require 'test/unit'

class LinkTest < Test::Unit::TestCase
  def test_link
    # todo: 重複が多いのでなんとかすること
    data = <<DATA
http://www.yahoo.co.jp/
http://www.google.co.jp/
DATA
    query = "/tmp/input" 
    f = open(query, "w")
    f.write(data)
    f.close

    output = "/tmp/output" 
    system("ruby link.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = <<EXPECT
<a href="http://www.yahoo.co.jp/">http://www.yahoo.co.jp/</a><br/>
<a href="http://www.google.co.jp/">http://www.google.co.jp/</a><br/>
EXPECT
    result = open(output).read
    assert_equal(expect, result)
  end

  def test_add_http
    data = <<DATA
www.yahoo.co.jp/
www.google.co.jp/
DATA
    query = "/tmp/input" 
    f = open(query, "w")
    f.write(data)
    f.close

    output = "/tmp/output" 
    system("ruby link.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = <<EXPECT
<a href="http://www.yahoo.co.jp/">http://www.yahoo.co.jp/</a><br/>
<a href="http://www.google.co.jp/">http://www.google.co.jp/</a><br/>
EXPECT
    result = open(output).read
    assert_equal(expect, result)
  end

  def test_no_record
    query = "/tmp/input" 
    f = open(query, "w")
    f.write("")
    f.close

    output = "/tmp/output" 
    system("ruby link.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = ""
    result = open(output).read
    assert_equal(expect, result)
  end
end
