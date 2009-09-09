#!/usr/bin/env ruby
require "test/unit"
require "append_to_tool_conf"

class AppendToToolConfTest < Test::Unit::TestCase
  def test_add_tool
    doc = REXML::Document.new <<-EOT
<?xml version="1.0"?>
<toolbox>
  <section name="Get Data" id="getext">
    <tool file="data_source/upload.xml"/>
  </section>
</toolbox>
    EOT
    
    add_tool(doc.root, "category", "tool")
    
    assert_equal <<-EOT, doc.to_s
<?xml version='1.0'?>
<toolbox>
  <section name='Get Data' id='getext'>
    <tool file='data_source/upload.xml'/>
  </section>
<section name='Category' id='category'><tool file='category/tool.xml'/></section></toolbox>
    EOT
  end

  def test_add_tool_when_that_already_conf_has_section
    doc = REXML::Document.new <<-EOT
<?xml version="1.0"?>
<toolbox>
  <section name="Get Data" id="getext">
    <tool file="data_source/upload.xml"/>
  </section>
  <section name='Category' id='category'>
    <tool file='category/already.xml'/>
  </section>
</toolbox>
    EOT
    
    add_tool(doc.root, "category", "tool")
    
    assert_equal <<-EOT, doc.to_s
<?xml version='1.0'?>
<toolbox>
  <section name='Get Data' id='getext'>
    <tool file='data_source/upload.xml'/>
  </section>
  <section name='Category' id='category'>
    <tool file='category/already.xml'/>
  <tool file='category/tool.xml'/></section>
</toolbox>
    EOT
  end

  def test_add_tool_when_that_already_conf_has_tool
    doc = REXML::Document.new <<-EOT
<?xml version="1.0"?>
<toolbox>
  <section name="Get Data" id="getext">
    <tool file="data_source/upload.xml"/>
  </section>
  <section name='Category' id='category'>
    <tool file='category/tool.xml'/>
  </section>
</toolbox>
    EOT
    
    add_tool(doc.root, "category", "tool")
    
    assert_equal <<-EOT, doc.to_s
<?xml version='1.0'?>
<toolbox>
  <section name='Get Data' id='getext'>
    <tool file='data_source/upload.xml'/>
  </section>
  <section name='Category' id='category'>
    <tool file='category/tool.xml'/>
  </section>
</toolbox>
    EOT
  end

  def test_appended_tool_conf
    xml = <<-EOT
<?xml version="1.0"?>
<toolbox>
<section name="Get Data" id="getext">
<tool file="data_source/upload.xml"/>
</section>
</toolbox>
    EOT
    
    assert_equal <<-EOT, appended_tool_conf(xml, "category", "tool")
<?xml version='1.0'?>
<toolbox>
  <section name='Get Data' id='getext'>
    <tool file='data_source/upload.xml'/>
  </section>
  <section name='Category' id='category'>
    <tool file='category/tool.xml'/>
  </section>
</toolbox>
    EOT
  end
end
