---
sidebar_position: 2
---

# GitHub Helpers

Advanced GitHub API helpers for custom integrations and data processing.

## GitHub API Helper

Direct access to the GitHub API with built-in authentication and rate limiting.

### Basic Usage

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Custom GitHub Integration"
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    # Get repository information
    repo_data = github.get("/repos/rails/rails")
    content.add_row("Repository: #{repo_data['full_name']}")
    content.add_row("Stars: #{repo_data['stargazers_count']}")
    content.add_row("Forks: #{repo_data['forks_count']}")
    content.add_row("Open issues: #{repo_data['open_issues_count']}")
    content.add_row("Language: #{repo_data['language']}")
  end
end
```

### Repository Analytics

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Repository Analytics"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    org = ENV['GITHUB_ORG']
    repo = ENV['GITHUB_REPO']
    
    begin
      # Repository stats
      repo_data = github.get("/repos/#{org}/#{repo}")
      
      # Recent commits (last 24 hours)
      commits = github.get("/repos/#{org}/#{repo}/commits", {
        per_page: 10,
        since: (Time.now - 24*60*60).iso8601
      })
      
      # Top contributors
      contributors = github.get("/repos/#{org}/#{repo}/contributors", {
        per_page: 5
      })
      
      # Repository information
      content.add_row("=== Repository Overview ===")
      content.add_row("Name: #{repo_data['full_name']}")
      content.add_row("Description: #{repo_data['description']}")
      content.add_row("⭐ Stars: #{repo_data['stargazers_count']}")
      content.add_row("🍴 Forks: #{repo_data['forks_count']}")
      content.add_row("📋 Open Issues: #{repo_data['open_issues_count']}")
      content.add_row("📅 Created: #{Date.parse(repo_data['created_at']).strftime('%Y-%m-%d')}")
      content.add_row("")
      
      # Recent activity
      content.add_row("=== Recent Commits (24h) ===")
      if commits.empty?
        content.add_row("No commits in the last 24 hours")
      else
        commits.each do |commit|
          author = commit['commit']['author']['name']
          message = commit['commit']['message'].split("\n").first[0, 60]
          message += "..." if commit['commit']['message'].length > 60
          content.add_row("#{author}: #{message}", commit)
        end
      end
      
      content.add_row("")
      
      # Top contributors
      content.add_row("=== Top Contributors ===")
      contributors.each do |contributor|
        content.add_row("#{contributor['login']}: #{contributor['contributions']} commits", contributor)
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |data|
    if data && data['html_url']
      `open #{data['html_url']}`
    end
  end
end
```

### GitHub Search Helper

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Search"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Search for repositories
      repo_results = github.search("ruby terminal dashboard", type: 'repositories')
      
      content.add_row("=== Repository Search Results ===")
      repo_results['items'][0, 5].each do |repo|
        stars = repo['stargazers_count']
        content.add_row("⭐ #{stars} - #{repo['full_name']}", repo)
      end
      
      content.add_row("")
      
      # Search for recent issues
      issue_results = github.search("is:issue is:open created:>#{(Date.today - 7).strftime('%Y-%m-%d')}", type: 'issues')
      
      content.add_row("=== Recent Issues (Last 7 Days) ===")
      issue_results['items'][0, 5].each do |issue|
        repo_name = issue['repository_url'].split('/').last(2).join('/')
        content.add_row("#{repo_name} ##{issue['number']}: #{issue['title']}", issue)
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |data|
    `open #{data['html_url']}`
  end
end
```

## Custom GitHub Utilities

### Repository Health Checker

```ruby title="Supfile"
class GitHubHealthChecker
  def self.check_repository(org, repo)
    github = Wassup::Helpers::GitHub.new
    
    begin
      repo_data = github.get("/repos/#{org}/#{repo}")
      
      # Check various health metrics
      health_score = 0
      issues = []
      
      # Recent activity (commits in last 30 days)
      commits = github.get("/repos/#{org}/#{repo}/commits", {
        per_page: 1,
        since: (Time.now - 30*24*60*60).iso8601
      })
      
      if commits.empty?
        issues << "No commits in last 30 days"
      else
        health_score += 20
      end
      
      # Documentation
      if repo_data['has_readme']
        health_score += 15
      else
        issues << "No README file"
      end
      
      # License
      if repo_data['license']
        health_score += 10
      else
        issues << "No license specified"
      end
      
      # Issues management
      open_issues = repo_data['open_issues_count']
      if open_issues < 10
        health_score += 15
      elsif open_issues < 50
        health_score += 10
      else
        issues << "Many open issues (#{open_issues})"
      end
      
      # Community engagement
      if repo_data['stargazers_count'] > 10
        health_score += 20
      end
      
      if repo_data['forks_count'] > 5
        health_score += 20
      end
      
      {
        score: health_score,
        issues: issues,
        data: repo_data
      }
    rescue => e
      {
        score: 0,
        issues: ["Error fetching data: #{e.message}"],
        data: nil
      }
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Repository Health Check"
  pane.interval = 60 * 15

  pane.content do |content|
    repositories = [
      ['rails', 'rails'],
      ['facebook', 'react'],
      ['microsoft', 'vscode']
    ]
    
    repositories.each do |org, repo|
      health = GitHubHealthChecker.check_repository(org, repo)
      
      color = case health[:score]
      when 80..100 then 'green'
      when 60..79 then 'yellow'
      else 'red'
      end
      
      content.add_row("[fg=#{color}]#{org}/#{repo}: #{health[:score]}/100")
      
      if health[:issues].any?
        health[:issues].each do |issue|
          content.add_row("  • #{issue}")
        end
      end
      
      content.add_row("")
    end
  end
end
```

### Team Activity Tracker

```ruby title="Supfile"
class GitHubTeamTracker
  def self.get_team_activity(org, team_members)
    github = Wassup::Helpers::GitHub.new
    activity = {}
    
    team_members.each do |member|
      begin
        # Get user's recent activity
        events = github.get("/users/#{member}/events", { per_page: 10 })
        
        # Filter for push events in the org
        org_activity = events.select do |event|
          event['type'] == 'PushEvent' && 
          event['repo']['name'].start_with?("#{org}/")
        end
        
        activity[member] = {
          total_events: events.length,
          org_activity: org_activity.length,
          last_activity: events.first ? events.first['created_at'] : nil
        }
      rescue => e
        activity[member] = {
          error: e.message
        }
      end
    end
    
    activity
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Team Activity"
  pane.interval = 60 * 30

  pane.content do |content|
    team_members = ['dhh', 'tenderlove', 'pixeltrix']  # Rails team examples
    org = 'rails'
    
    activity = GitHubTeamTracker.get_team_activity(org, team_members)
    
    content.add_row("=== Team Activity Summary ===")
    
    activity.each do |member, data|
      if data[:error]
        content.add_row("[fg=red]#{member}: Error - #{data[:error]}")
      else
        last_activity = data[:last_activity] ? 
          Time.parse(data[:last_activity]).strftime('%m/%d %H:%M') : 
          'Never'
        
        content.add_row("#{member}:")
        content.add_row("  Recent events: #{data[:total_events]}")
        content.add_row("  Org activity: #{data[:org_activity]}")
        content.add_row("  Last seen: #{last_activity}")
        content.add_row("")
      end
    end
  end
end
```

## Rate Limiter Utilities

### Advanced Rate Limit Management

```ruby title="Supfile"
class GitHubRateLimitManager
  def self.status_summary
    status = Wassup::Helpers::GitHub::RateLimiter.status
    
    {
      core: {
        remaining: status[:remaining],
        limit: status[:limit],
        reset_at: status[:reset_at],
        percentage: (status[:remaining].to_f / status[:limit].to_f * 100).round(1)
      },
      search: {
        remaining: status[:search_remaining],
        limit: status[:search_limit] || 30,
        reset_at: status[:search_reset_at],
        percentage: (status[:search_remaining].to_f / (status[:search_limit] || 30).to_f * 100).round(1)
      },
      queue: {
        size: status[:queue_size],
        running: status[:running]
      }
    }
  end
  
  def self.wait_time_estimate
    status = Wassup::Helpers::GitHub::RateLimiter.status
    
    if status[:remaining] < 10
      reset_time = Time.parse(status[:reset_at])
      seconds_until_reset = [(reset_time - Time.now).to_i, 0].max
      "#{seconds_until_reset / 60}m #{seconds_until_reset % 60}s"
    else
      "No wait needed"
    end
  end
end

add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Rate Limit Monitor"
  pane.interval = 30

  pane.content do |content|
    summary = GitHubRateLimitManager.status_summary
    
    content.add_row("=== Core API ===")
    core_color = summary[:core][:percentage] > 25 ? 'green' : summary[:core][:percentage] > 10 ? 'yellow' : 'red'
    content.add_row("[fg=#{core_color}]#{summary[:core][:remaining]}/#{summary[:core][:limit]} (#{summary[:core][:percentage]}%)")
    content.add_row("Reset: #{summary[:core][:reset_at]}")
    
    content.add_row("")
    content.add_row("=== Search API ===")
    search_color = summary[:search][:percentage] > 25 ? 'green' : summary[:search][:percentage] > 10 ? 'yellow' : 'red'
    content.add_row("[fg=#{search_color}]#{summary[:search][:remaining]}/#{summary[:search][:limit]} (#{summary[:search][:percentage]}%)")
    content.add_row("Reset: #{summary[:search][:reset_at]}")
    
    content.add_row("")
    content.add_row("=== Queue Status ===")
    queue_color = summary[:queue][:size] > 10 ? 'red' : summary[:queue][:size] > 5 ? 'yellow' : 'green'
    content.add_row("[fg=#{queue_color}]Queue size: #{summary[:queue][:size]}")
    content.add_row("Worker running: #{summary[:queue][:running] ? 'Yes' : 'No'}")
    
    wait_time = GitHubRateLimitManager.wait_time_estimate
    if wait_time != "No wait needed"
      content.add_row("[fg=yellow]Wait time: #{wait_time}")
    end
  end
end
```

## Data Processing Helpers

### GitHub Data Aggregator

```ruby title="Supfile"
class GitHubDataAggregator
  def self.aggregate_repository_stats(repositories)
    github = Wassup::Helpers::GitHub.new
    stats = {
      total_stars: 0,
      total_forks: 0,
      total_issues: 0,
      languages: {},
      repositories: []
    }
    
    repositories.each do |org, repo|
      begin
        data = github.get("/repos/#{org}/#{repo}")
        
        stats[:total_stars] += data['stargazers_count']
        stats[:total_forks] += data['forks_count']
        stats[:total_issues] += data['open_issues_count']
        
        if data['language']
          stats[:languages][data['language']] ||= 0
          stats[:languages][data['language']] += 1
        end
        
        stats[:repositories] << {
          name: data['full_name'],
          stars: data['stargazers_count'],
          forks: data['forks_count'],
          issues: data['open_issues_count'],
          language: data['language']
        }
      rescue => e
        stats[:repositories] << {
          name: "#{org}/#{repo}",
          error: e.message
        }
      end
    end
    
    stats
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Repository Portfolio"
  pane.interval = 60 * 20

  pane.content do |content|
    repositories = [
      ['rails', 'rails'],
      ['rails', 'activesupport'],
      ['rails', 'activerecord']
    ]
    
    stats = GitHubDataAggregator.aggregate_repository_stats(repositories)
    
    content.add_row("=== Portfolio Summary ===")
    content.add_row("Total Stars: #{stats[:total_stars]}")
    content.add_row("Total Forks: #{stats[:total_forks]}")
    content.add_row("Total Open Issues: #{stats[:total_issues]}")
    
    content.add_row("")
    content.add_row("=== Languages ===")
    stats[:languages].each do |language, count|
      content.add_row("#{language}: #{count} repositories")
    end
    
    content.add_row("")
    content.add_row("=== Individual Repositories ===")
    stats[:repositories].each do |repo|
      if repo[:error]
        content.add_row("[fg=red]#{repo[:name]}: #{repo[:error]}")
      else
        content.add_row("#{repo[:name]} (#{repo[:language]})")
        content.add_row("  ⭐ #{repo[:stars]} 🍴 #{repo[:forks]} 📋 #{repo[:issues]}")
      end
    end
  end
end
```

## Next Steps

- [GitHub Formatters](./formatters.md) - Format GitHub data for display
- [GitHub Examples](./examples.md) - Real-world GitHub dashboard examples
- [Other Integrations](../netlify/setup.md) - Netlify, CircleCI, and Shortcut