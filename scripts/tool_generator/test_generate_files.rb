#!/usr/bin/env ruby
require "test/unit"
require "generate_files"

class GenerateFilesTest < Test::Unit::TestCase
  def test_expand_variables
    assert_equal "hoge fuga piyo", expand_variables("hoge __bbb__ piyo", "__bbb__" => "fuga")
  end

  def test_variables
    assert_equal({
                   "__tool_id__" => "hoge_fuga",
                   "__tool_name__" => "Hoge Fuga"
                 },
                 variables("hoge_fuga")
                 )
  end
end
