require 'time'
require 'rest-client'
require 'json'

#
# Top Left
#
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

#
# Top Right
#
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.75
  pane.top = 0
  pane.left = 0.25

  pane.highlight = true

  pane.title = "Open PRs - fastlane-community"

  pane.interval = 60 * 5
  pane.content do
    resp = RestClient::Request.execute(
      method: :get, 
      url: "https://api.github.com/orgs/fastlane-community/repos", 
      user: ENV["WASSUP_GITHUB_USERNAME"],
      password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
    )
    json = JSON.parse(resp)
    json.map do |repo|
      full_name = repo["full_name"]

      resp = RestClient::Request.execute(
        method: :get, 
        url: "https://api.github.com/repos/#{full_name}/pulls",
        user: ENV["WASSUP_GITHUB_USERNAME"],
        password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
      )
      json = JSON.parse(resp)
      json.map do |pr|
        number = pr["number"]
        title = pr["title"]
        created_at = pr["created_at"]

        number_formatted = '%5.5s' % "##{number}"

        date = Time.parse(created_at)
        days = (Time.now - date).to_i / (24 * 60 * 60)
        days_formatted = '%3.3s' % days.to_s

        ["#{number_formatted} #{days_formatted}d ago #{title}",pr]
      end
    end.flatten(1)
  end
  pane.selection do |data|
    url = data["html_url"] 
    `open #{url}`
  end
end

#
# Bottom Left
#
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

#
# Bottom Right
#
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.75
  pane.top = 0.5
  pane.left = 0.25

  pane.highlight = true

  pane.title = "Open PRs - fastlane/fastlane"

  pane.interval = 60 * 5
  pane.content do
    resp = RestClient::Request.execute(
      method: :get, 
      url: "https://api.github.com/repos/fastlane/fastlane/pulls", 
      user: ENV["WASSUP_GITHUB_USERNAME"],
      password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
    )
    json = JSON.parse(resp)
    json.map do |pr|
      number = pr["number"]
      title = pr["title"]
      created_at = pr["created_at"]

      date = Time.parse(created_at)
      days = (Time.now - date).to_i / (24 * 60 * 60)
      days_formatted = '%3.3s' % days.to_s

      ["##{number} #{days_formatted}d ago #{title}",pr]
    end
  end
  pane.selection do |data|
    url = data["html_url"] 
    `open #{url}`
  end
end
