require 'test/unit'

class PdbjLocationTest < Test::Unit::TestCase
  def test_pdbj_location
    data = <<DATA
1A4U
1AA7
3C7N
DATA
    query = "/tmp/input" 
    f = open(query, "w")
    f.write(data)
    f.close

    output = "/tmp/output" 
    system("ruby pdbj_location.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = <<EXPECT
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=1A4U&PAGEID=Interactive2
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=1AA7&PAGEID=Interactive2
http://pdbjs3.protein.osaka-u.ac.jp/xPSSS/DetailServlet?PDBID=3C7N&PAGEID=Interactive2
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
    system("ruby pdbj_location.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = ""
    result = open(output).read
    assert_equal(expect, result)
  end
end
