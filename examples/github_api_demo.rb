#!/usr/bin/env ruby

require_relative '../lib/wassup/helpers/github'

# Example demonstrating how to use the new GitHub API method
# to replace manual RestClient requests with rate-limited API calls

# Instead of manual RestClient calls like:
# resp = RestClient::Request.execute(
#   method: :get, 
#   url: "https://api.github.com/repos/owner/repo/pulls/123", 
#   user: ENV["WASSUP_GITHUB_USERNAME"],
#   password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
# )
# pr = JSON.parse(resp)

# Use the new GitHub API method:
org = "your-org"
repo = "your-repo"
pr_number = 123

# Get PR data
pr = Wassup::Helpers::GitHub.api(path: "/repos/#{org}/#{repo}/pulls/#{pr_number}")

puts "PR: #{pr['title']}"
puts "Draft: #{pr['draft']}"
puts "Requested reviewers: #{pr['requested_reviewers'].size}"
puts "Requested teams: #{pr['requested_teams'].size}"

# Get PR reviews
reviews = Wassup::Helpers::GitHub.api(path: "/repos/#{org}/#{repo}/pulls/#{pr_number}/reviews")

# Filter out your own reviews
reviews = reviews.select { |review| review["user"]["login"] != "your-username" }

approved = reviews.count { |review| review["state"] == "APPROVED" }
changes_requested = reviews.count { |review| review["state"] == "CHANGES_REQUESTED" }

puts "Approved: #{approved}"
puts "Changes requested: #{changes_requested}"

# Get check runs for the PR's head commit
head_sha = pr["head"]["sha"]
check_runs = Wassup::Helpers::GitHub.api(path: "/repos/#{org}/#{repo}/commits/#{head_sha}/check-runs")

puts "Check runs: #{check_runs['check_runs'].size}"

# Get commit statuses
statuses = Wassup::Helpers::GitHub.api(path: "/repos/#{org}/#{repo}/commits/#{head_sha}/statuses")

puts "Statuses: #{statuses.size}"

# Count different status types
success_count = statuses.count { |status| status["state"] == "success" }
failure_count = statuses.count { |status| status["state"] == "failure" }

puts "Success: #{success_count}, Failures: #{failure_count}"

# Example with query parameters
# Get PRs with specific state
open_prs = Wassup::Helpers::GitHub.api(
  path: "/repos/#{org}/#{repo}/pulls", 
  params: { state: "open", per_page: 10 }
)

puts "Open PRs: #{open_prs.size}"

# Example with POST request (creating an issue comment)
# comment_body = { body: "This is a test comment" }
# new_comment = Wassup::Helpers::GitHub.api(
#   path: "/repos/#{org}/#{repo}/issues/#{pr_number}/comments",
#   method: :post,
#   body: comment_body
# )