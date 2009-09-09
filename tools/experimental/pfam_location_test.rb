require 'test/unit'

class PfamLocationTest < Test::Unit::TestCase
  def test_pfam_location
    data = <<DATA
7TM_GPCR_Srv
TAS2R
DUF1123
Ctr
DATA
    query = "/tmp/input" 
    f = open(query, "w")
    f.write(data)
    f.close

    output = "/tmp/output" 
    system("ruby pfam_location.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = <<EXPECT
http://pfam.sanger.ac.uk/family?entry=7TM_GPCR_Srv
http://pfam.sanger.ac.uk/family?entry=TAS2R
http://pfam.sanger.ac.uk/family?entry=DUF1123
http://pfam.sanger.ac.uk/family?entry=Ctr
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
    system("ruby pfam_location.rb --input-file \"/tmp/input\" -o \"/tmp/output\"")

    expect = ""
    result = open(output).read
    assert_equal(expect, result)
  end
end
