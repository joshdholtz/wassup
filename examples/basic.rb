require 'time'
require 'rest-client'
require 'json'
require 'colorize'

#
# Top Left 1
#
add_pane do |pane|
  pane.height = 0.25
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
# Top Left 2
#
add_pane do |pane|
  pane.height = 0.25
  pane.width = 0.25
  pane.top = 0.25
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
      name = repo["name"]
      full_name = repo["full_name"]

      resp = RestClient::Request.execute(
        method: :get, 
        url: "https://api.github.com/repos/#{full_name}/pulls",
        user: ENV["WASSUP_GITHUB_USERNAME"],
        password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
      )
      json = JSON.parse(resp)
      prs = json.map do |pr|
        number = pr["number"]
        title = pr["title"]
        created_at = pr["created_at"]

        number_formatted = '%5.5s' % "##{number}"

        date = Time.parse(created_at)
        days = (Time.now - date).to_i / (24 * 60 * 60)
        days_formatted = '%3.3s' % days.to_s

        ["#{number_formatted} #{days_formatted}d ago #{title}",pr]
      end

      {
        title: name,
        content: prs
      }
    end
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
  pane.width = 0.5
  pane.top = 0.5
  pane.left = 0

  pane.highlight = true

  pane.title = "Circle CI - fastlane/fastlane - main branch"

  pane.interval = 60 * 5
  pane.content do 
    resp = RestClient::Request.execute(
      method: :get, 
      url: "https://circleci.com/api/v2/project/github/fastlane/fastlane/pipeline?branch=master", 
      headers: { "Circle-Token": ENV["WASSUP_CIRCLE_CI_API_TOKEN"] }
    )
    json = JSON.parse(resp)
    json["items"].map do |item|
      id = item["id"]
      number = item["number"]
      message = item["vcs"]["commit"]["subject"]
      login = item["trigger"]["actor"]["login"]

      resp = RestClient::Request.execute(
        method: :get, 
        url: "https://circleci.com/api/v2/pipeline/#{id}/workflow", 
        headers: { "Circle-Token": ENV["WASSUP_CIRCLE_CI_API_TOKEN"] }
      )
      json = JSON.parse(resp)
      workflow = json["items"].first
      status = workflow["status"]

      ["#{number} (#{status}) by #{login} - #{message}", workflow]
    end
  end
  pane.selection do |data|
    slug = data["project_slug"]
    pipeline_number = data["pipeline_number"]
    workflow_id = data["id"]

    url = "https://app.circleci.com/pipelines/#{slug}/#{pipeline_number}/workflows/#{workflow_id}"
    `open #{url}`
  end
end

#
# Bottom Right
#
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0.5
  pane.left = 0.5

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
