require "rubygems"
require "mechanize"
require "singleton"

class Galaxy
  class NotEstablishAgentError < StandardError; end

  BASE_URL = 'http://localhost:37280'
  attr_reader :agent

  def self.establish_agent(user_id)
    @agent = WWW::Mechanize.new
    @agent.request_headers["REMOTE_USER"] = user_id
    @agent.get BASE_URL + "/"
  end
  
  def self.agent
    @agent or raise NotEstablishAgentError
  end

  def self.run_workflow(workflow_id, dataset_id=nil)
    agent.get BASE_URL + "/workflow/run?id=#{workflow_id}"
    agent.page.form_with(:name => "tool_form") do |form|
      if dataset_id and select = agent.page.root.css("form#tool_form select")[0]
        query_param_name = select["name"]
        form.field_with(:name => query_param_name).value = dataset_id
      end
      form.click_button
    end
    agent.page.root.css("div.donemessage div p").map do |e|
      e.text.split(":").first.to_i
    end
  end
end
