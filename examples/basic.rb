require 'time'
require 'rest-client'
require 'json'

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.25
  pane.top = 0
  pane.left = 0

  pane.highlight = false

  pane.title = "Date & Time"

  pane.interval = 1
  pane.content do
    [
      Time.now.to_s,
    ] 
  end
end

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.75
  pane.top = 0
  pane.left = 0.25

  pane.highlight = true

  pane.title = "Open PRs - fastlane/fastane"

  pane.interval = 60 * 5
  pane.content do
    resp = RestClient.get "https://api.github.com/repos/fastlane/fastlane/pulls"
    json = JSON.parse(resp)
    json.map do |pr|
      number = pr["number"]
      title = pr["title"]
      created_at = pr["created_at"]

      date = Time.parse(created_at)
      days = (Time.now - date).to_i / (24 * 60 * 60)
      days_formatted = '%3.3s' % days.to_s

      "##{number} #{days_formatted}d ago #{title}"
    end
  end
end

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.25
  pane.top = 0.5
  pane.left = 0

  pane.highlight = false

  pane.title = "Bottom Left"

  pane.interval = 60 * 5
  pane.content do 
    [
      "Other",
      "Stuff",
      "Goes",
      "Here"
    ]
  end
end


add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.75
  pane.top = 0.5
  pane.left = 0.25

  pane.highlight = true

  pane.title = "Bottom Right"

  pane.interval = 60 * 5
  pane.content do 
    [
      "Other",
      "Stuff",
      "Goes",
      "Here"
    ]
  end
end
