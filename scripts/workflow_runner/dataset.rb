require "rubygems"
require "json"
require "galaxy"

class Dataset
  attr_accessor :id, :history_number

  def self.all
    Galaxy.agent.get Galaxy::BASE_URL + "/history"
    Galaxy.agent.page.root.css("div.historyItem").map do |e|
      dataset = self.new
      dataset.id = e["id"].split("-")[1]
      dataset.history_number =  e.css("span.historyItemTitle").css("b").text.split(":")[0].to_i
      dataset
    end
  end

  def self.upload(content)
    Galaxy.agent.get Galaxy::BASE_URL + "/tool_runner?tool_id=upload1"
    Galaxy.agent.page.form_with(:name => "tool_form") do |form|
      form.field_with(:name => "files_0|url_paste").value = content 
      form.click_button
    end
    title = Galaxy.agent.page.root.css("div.donemessage div b").first.text
    history_number = title.match(/(\d+): Pasted Entry/)[1].to_i
    find_by_history_numbers([history_number]).first
  end

  def self.find_by_history_numbers(history_numbers)
    all.select{|d| history_numbers.include?(d.history_number)}
  end

  def self.generating?(datasets)
    datasets.any? do |dataset|
      dataset.generating?
    end
  end

  def self.wait(datasets)
    while generating?(datasets)
      sleep 1
    end
  end

  def generating?
    Galaxy.agent.post("/root/history_item_updates", "ids" => id, "states" => "queued")
    result = JSON.parse(Galaxy.agent.page.body)
    if result.empty?
      true
    else
      state = result[id.to_s]["state"]
      if state == "running"
        true
      else
        false
      end
    end
  rescue
    true
  end
end
