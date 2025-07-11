---
sidebar_position: 4
---

# GitHub Examples

Real-world GitHub dashboard configurations and integration examples.

## Complete GitHub Dashboard

### Full-Featured Repository Monitor

```ruby title="Supfile"
# Main repository overview
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Rails Repository Overview"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      repo = github.get("/repos/rails/rails")
      
      content.add_row("Repository: #{repo['full_name']}")
      content.add_row("⭐ Stars: #{repo['stargazers_count']} | 🍴 Forks: #{repo['forks_count']}")
      content.add_row("📋 Open Issues: #{repo['open_issues_count']}")
      content.add_row("📅 Last Update: #{Time.parse(repo['updated_at']).strftime('%Y-%m-%d %H:%M')}")
      content.add_row("🏠 Language: #{repo['language']}")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end

# Active pull requests
add_pane do |pane|
  pane.height = 0.35; pane.width = 0.5; pane.top = 0.3; pane.left = 0
  pane.title = "Active Pull Requests"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
  
  pane.selection do |pr|
    system("open #{pr['html_url']}")
  end
end

# Recent issues
add_pane do |pane|
  pane.height = 0.35; pane.width = 0.5; pane.top = 0.3; pane.left = 0.5
  pane.title = "Recent Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'rails',
    repo: 'rails',
    query: 'is:issue is:open sort:updated-desc'
  )
  
  pane.selection do |issue|
    system("open #{issue['html_url']}")
  end
end

# Rate limit and status
add_pane do |pane|
  pane.height = 0.35; pane.width = 1.0; pane.top = 0.65; pane.left = 0
  pane.title = "GitHub API Status"
  pane.interval = 60

  pane.content do |content|
    status = Wassup::Helpers::GitHub::RateLimiter.status
    
    remaining_pct = (status[:remaining].to_f / status[:limit].to_f) * 100
    
    content.add_row("Core API: #{status[:remaining]}/#{status[:limit]} (#{remaining_pct.round(1)}%)")
    
    if remaining_pct > 25
      content.add_row("[fg=green]✓ Rate limit healthy")
    elsif remaining_pct > 10
      content.add_row("[fg=yellow]⚠ Rate limit getting low")
    else
      content.add_row("[fg=red]⚠ Rate limit critical")
    end
    
    content.add_row("Reset at: #{status[:reset_at]}")
    content.add_row("Queue size: #{status[:queue_size]}")
  end
end
```

## Multi-Repository Dashboard

### Team Repository Overview

```ruby title="Supfile"
# Configuration
REPOSITORIES = [
  ['rails', 'rails'],
  ['rails', 'activesupport'],
  ['rails', 'activerecord'],
  ['rails', 'actionpack']
]

# Repository summary
add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Rails Ecosystem Overview"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    total_stars = 0
    total_forks = 0
    total_issues = 0
    
    content.add_row("=== Repository Health ===")
    
    REPOSITORIES.each do |org, repo|
      begin
        data = github.get("/repos/#{org}/#{repo}")
        
        stars = data['stargazers_count']
        forks = data['forks_count']
        issues = data['open_issues_count']
        
        total_stars += stars
        total_forks += forks
        total_issues += issues
        
        status_color = issues > 50 ? 'red' : issues > 20 ? 'yellow' : 'green'
        
        content.add_row("[fg=#{status_color}]#{repo}: ⭐ #{stars} 🍴 #{forks} 📋 #{issues}", data)
        
      rescue => e
        content.add_row("[fg=red]#{repo}: Error - #{e.message}")
      end
    end
    
    content.add_row("")
    content.add_row("=== Totals ===")
    content.add_row("Total Stars: #{total_stars}")
    content.add_row("Total Forks: #{total_forks}")
    content.add_row("Total Issues: #{total_issues}")
  end
  
  pane.selection do |repo_data|
    system("open #{repo_data['html_url']}")
  end
end

# Recent activity across repositories
add_pane do |pane|
  pane.height = 0.6; pane.width = 1.0; pane.top = 0.4; pane.left = 0
  pane.title = "Recent Activity"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    all_activity = []
    
    REPOSITORIES.each do |org, repo|
      begin
        # Get recent commits
        commits = github.get("/repos/#{org}/#{repo}/commits", { per_page: 5 })
        
        commits.each do |commit|
          all_activity << {
            type: 'commit',
            repo: repo,
            message: commit['commit']['message'].split("\n").first,
            author: commit['commit']['author']['name'],
            date: commit['commit']['author']['date'],
            url: commit['html_url']
          }
        end
        
        # Get recent issues
        issues = github.get("/repos/#{org}/#{repo}/issues", { 
          per_page: 3,
          state: 'open',
          sort: 'updated'
        })
        
        issues.each do |issue|
          all_activity << {
            type: 'issue',
            repo: repo,
            title: issue['title'],
            number: issue['number'],
            date: issue['updated_at'],
            url: issue['html_url']
          }
        end
        
      rescue => e
        content.add_row("[fg=red]#{repo}: #{e.message}")
      end
    end
    
    # Sort by date and show recent activity
    all_activity.sort_by! { |item| Time.parse(item[:date]) }
    all_activity.reverse!
    
    content.add_row("=== Recent Activity ===")
    
    all_activity.first(20).each do |item|
      case item[:type]
      when 'commit'
        content.add_row("💻 #{item[:repo]}: #{item[:message]} (#{item[:author]})", item)
      when 'issue'
        content.add_row("📋 #{item[:repo]}: ##{item[:number]} #{item[:title]}", item)
      end
    end
  end
  
  pane.selection do |activity|
    system("open #{activity[:url]}")
  end
end
```

## Issue Tracking Dashboard

### Bug Triage and Management

```ruby title="Supfile"
# Critical bugs
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Critical Bugs"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Search for critical bugs
      results = github.search('is:issue is:open label:bug label:critical', type: 'issues')
      
      if results['items'].empty?
        content.add_row("[fg=green]✓ No critical bugs!")
      else
        content.add_row("[fg=red]⚠ #{results['items'].length} critical bugs found")
        content.add_row("")
        
        results['items'].first(8).each do |issue|
          repo_name = issue['repository_url'].split('/').last(2).join('/')
          age_days = (Time.now - Time.parse(issue['created_at'])) / (24 * 60 * 60)
          
          color = age_days > 7 ? 'red' : age_days > 3 ? 'yellow' : 'white'
          
          content.add_row("[fg=#{color}]#{repo_name} ##{issue['number']}: #{issue['title']}", issue)
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |issue|
    system("open #{issue['html_url']}")
  end
end

# Issue statistics
add_pane do |pane|
  pane.height = 0.35; pane.width = 0.5; pane.top = 0.3; pane.left = 0
  pane.title = "Issue Statistics"
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get issue statistics
      stats = {
        'bug' => 0,
        'enhancement' => 0,
        'documentation' => 0,
        'question' => 0
      }
      
      stats.each do |label, count|
        results = github.search("is:issue is:open label:#{label}", type: 'issues')
        stats[label] = results['total_count']
      end
      
      content.add_row("=== Issue Breakdown ===")
      content.add_row("[fg=red]🐛 Bugs: #{stats['bug']}")
      content.add_row("[fg=green]✨ Enhancements: #{stats['enhancement']}")
      content.add_row("[fg=blue]📚 Documentation: #{stats['documentation']}")
      content.add_row("[fg=yellow]❓ Questions: #{stats['question']}")
      
      total = stats.values.sum
      content.add_row("")
      content.add_row("Total Open Issues: #{total}")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end

# Recent issue activity
add_pane do |pane|
  pane.height = 0.35; pane.width = 0.5; pane.top = 0.3; pane.left = 0.5
  pane.title = "Recent Issue Activity"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get recently updated issues
      results = github.search('is:issue sort:updated-desc', type: 'issues')
      
      content.add_row("=== Recently Updated ===")
      
      results['items'].first(10).each do |issue|
        repo_name = issue['repository_url'].split('/').last(2).join('/')
        updated_at = Time.parse(issue['updated_at'])
        time_ago = ((Time.now - updated_at) / 3600).round(1)
        
        status_color = issue['state'] == 'open' ? 'green' : 'white'
        
        content.add_row("[fg=#{status_color}]#{repo_name} ##{issue['number']}: #{issue['title']}", issue)
        content.add_row("  Updated #{time_ago}h ago")
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |issue|
    system("open #{issue['html_url']}")
  end
end

# My assigned issues
add_pane do |pane|
  pane.height = 0.35; pane.width = 1.0; pane.top = 0.65; pane.left = 0
  pane.title = "My Assigned Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    username = ENV['WASSUP_GITHUB_USERNAME']
    
    begin
      # Get issues assigned to me
      results = github.search("is:issue is:open assignee:#{username}", type: 'issues')
      
      if results['items'].empty?
        content.add_row("[fg=green]✓ No assigned issues")
      else
        content.add_row("#{results['items'].length} issues assigned to you")
        content.add_row("")
        
        results['items'].each do |issue|
          repo_name = issue['repository_url'].split('/').last(2).join('/')
          
          # Determine priority based on labels
          priority = 'normal'
          if issue['labels'].any? { |l| l['name'].downcase.include?('urgent') }
            priority = 'urgent'
          elsif issue['labels'].any? { |l| l['name'].downcase.include?('high') }
            priority = 'high'
          end
          
          color = case priority
          when 'urgent' then 'red'
          when 'high' then 'yellow'
          else 'white'
          end
          
          content.add_row("[fg=#{color}]#{repo_name} ##{issue['number']}: #{issue['title']}", issue)
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |issue|
    system("open #{issue['html_url']}")
  end
end
```

## Development Team Dashboard

### Team Activity and Collaboration

```ruby title="Supfile"
# Team member configuration
TEAM_MEMBERS = ['dhh', 'tenderlove', 'pixeltrix', 'kaspth']
TEAM_REPOS = [
  ['rails', 'rails'],
  ['rails', 'activesupport'],
  ['rails', 'activerecord']
]

# Team activity overview
add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Team Activity Overview"
  pane.highlight = true
  pane.interval = 60 * 15

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    content.add_row("=== Team Activity (Last 7 Days) ===")
    
    TEAM_MEMBERS.each do |member|
      begin
        # Get recent activity
        events = github.get("/users/#{member}/events", { per_page: 30 })
        
        # Filter to team repositories and recent activity
        recent_events = events.select do |event|
          event_date = Time.parse(event['created_at'])
          days_ago = (Time.now - event_date) / (24 * 60 * 60)
          
          days_ago <= 7 && TEAM_REPOS.any? do |org, repo|
            event['repo'] && event['repo']['name'] == "#{org}/#{repo}"
          end
        end
        
        # Count activity types
        push_events = recent_events.count { |e| e['type'] == 'PushEvent' }
        pr_events = recent_events.count { |e| e['type'] == 'PullRequestEvent' }
        issue_events = recent_events.count { |e| e['type'] == 'IssuesEvent' }
        
        total_activity = push_events + pr_events + issue_events
        
        color = total_activity > 10 ? 'green' : total_activity > 5 ? 'yellow' : 'red'
        
        content.add_row("[fg=#{color}]#{member}: #{total_activity} actions (#{push_events} commits, #{pr_events} PRs, #{issue_events} issues)", {
          member: member,
          activity: total_activity,
          commits: push_events,
          prs: pr_events,
          issues: issue_events
        })
        
      rescue => e
        content.add_row("[fg=red]#{member}: Error - #{e.message}")
      end
    end
  end
  
  pane.selection do |member_data|
    system("open https://github.com/#{member_data[:member]}")
  end
end

# Open pull requests requiring review
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.4; pane.left = 0
  pane.title = "PRs Needing Review"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    all_prs = []
    
    TEAM_REPOS.each do |org, repo|
      begin
        prs = github.get("/repos/#{org}/#{repo}/pulls", { state: 'open' })
        
        prs.each do |pr|
          # Check if PR needs review (simplified logic)
          if pr['requested_reviewers'].any? || pr['requested_teams'].any?
            all_prs << {
              repo: repo,
              number: pr['number'],
              title: pr['title'],
              author: pr['user']['login'],
              created_at: pr['created_at'],
              url: pr['html_url']
            }
          end
        end
        
      rescue => e
        content.add_row("[fg=red]#{repo}: #{e.message}")
      end
    end
    
    if all_prs.empty?
      content.add_row("[fg=green]✓ No PRs waiting for review")
    else
      content.add_row("#{all_prs.length} PRs need review")
      content.add_row("")
      
      all_prs.sort_by! { |pr| Time.parse(pr[:created_at]) }
      
      all_prs.first(8).each do |pr|
        age_days = (Time.now - Time.parse(pr[:created_at])) / (24 * 60 * 60)
        age_color = age_days > 3 ? 'red' : age_days > 1 ? 'yellow' : 'green'
        
        content.add_row("[fg=#{age_color}]#{pr[:repo]} ##{pr[:number]}: #{pr[:title]}", pr)
        content.add_row("  by #{pr[:author]} (#{age_days.round(1)}d ago)")
      end
    end
  end
  
  pane.selection do |pr|
    system("open #{pr[:url]}")
  end
end

# Recent releases
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.4; pane.left = 0.5
  pane.title = "Recent Releases"
  pane.highlight = true
  pane.interval = 60 * 30

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    all_releases = []
    
    TEAM_REPOS.each do |org, repo|
      begin
        releases = github.get("/repos/#{org}/#{repo}/releases", { per_page: 3 })
        
        releases.each do |release|
          all_releases << {
            repo: repo,
            tag: release['tag_name'],
            name: release['name'],
            published_at: release['published_at'],
            prerelease: release['prerelease'],
            url: release['html_url']
          }
        end
        
      rescue => e
        content.add_row("[fg=red]#{repo}: #{e.message}")
      end
    end
    
    all_releases.sort_by! { |r| Time.parse(r[:published_at]) }
    all_releases.reverse!
    
    content.add_row("=== Recent Releases ===")
    
    all_releases.first(8).each do |release|
      days_ago = (Time.now - Time.parse(release[:published_at])) / (24 * 60 * 60)
      
      color = release[:prerelease] ? 'yellow' : 'green'
      pre_text = release[:prerelease] ? ' (pre-release)' : ''
      
      content.add_row("[fg=#{color}]#{release[:repo]} #{release[:tag]}#{pre_text}", release)
      content.add_row("  #{days_ago.round(1)}d ago")
    end
  end
  
  pane.selection do |release|
    system("open #{release[:url]}")
  end
end

# Build and CI status
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0.7; pane.left = 0
  pane.title = "Build Status"
  pane.interval = 60 * 3

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    content.add_row("=== CI Status ===")
    
    TEAM_REPOS.each do |org, repo|
      begin
        # Get workflow runs for main branch
        runs = github.get("/repos/#{org}/#{repo}/actions/runs", { 
          branch: 'main',
          per_page: 1
        })
        
        if runs['workflow_runs'].any?
          latest_run = runs['workflow_runs'].first
          status = latest_run['status']
          conclusion = latest_run['conclusion']
          
          case conclusion
          when 'success'
            color = 'green'
            icon = '✓'
          when 'failure'
            color = 'red'
            icon = '✗'
          when 'cancelled'
            color = 'yellow'
            icon = '⚠'
          else
            color = 'blue'
            icon = '●'
          end
          
          content.add_row("[fg=#{color}]#{icon} #{repo}: #{status} (#{conclusion})")
        else
          content.add_row("[fg=white]#{repo}: No recent builds")
        end
        
      rescue => e
        content.add_row("[fg=red]#{repo}: #{e.message}")
      end
    end
  end
end
```

## Personal GitHub Dashboard

### Individual Developer Focus

```ruby title="Supfile"
# Personal configuration
MY_USERNAME = ENV['WASSUP_GITHUB_USERNAME']
WATCHING_REPOS = [
  ['rails', 'rails'],
  ['ruby', 'ruby'],
  ['github', 'gh-cli']
]

# My GitHub activity
add_pane do |pane|
  pane.height = 0.25; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "My GitHub Activity"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get my recent activity
      events = github.get("/users/#{MY_USERNAME}/events", { per_page: 10 })
      
      content.add_row("=== Recent Activity ===")
      
      events.each do |event|
        case event['type']
        when 'PushEvent'
          commits = event['payload']['commits'].length
          repo = event['repo']['name']
          content.add_row("📤 Pushed #{commits} commit(s) to #{repo}", event)
          
        when 'PullRequestEvent'
          action = event['payload']['action']
          pr = event['payload']['pull_request']
          repo = event['repo']['name']
          content.add_row("🔀 #{action.capitalize} PR ##{pr['number']} in #{repo}", event)
          
        when 'IssuesEvent'
          action = event['payload']['action']
          issue = event['payload']['issue']
          repo = event['repo']['name']
          content.add_row("📋 #{action.capitalize} issue ##{issue['number']} in #{repo}", event)
          
        when 'CreateEvent'
          ref_type = event['payload']['ref_type']
          repo = event['repo']['name']
          content.add_row("✨ Created #{ref_type} in #{repo}", event)
          
        when 'WatchEvent'
          repo = event['repo']['name']
          content.add_row("⭐ Starred #{repo}", event)
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |event|
    if event['repo']
      system("open https://github.com/#{event['repo']['name']}")
    end
  end
end

# Notifications and mentions
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.25; pane.left = 0
  pane.title = "My Notifications"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get notifications
      notifications = github.get("/notifications", { per_page: 10 })
      
      if notifications.empty?
        content.add_row("[fg=green]✓ No new notifications")
      else
        content.add_row("#{notifications.length} new notifications")
        content.add_row("")
        
        notifications.each do |notification|
          repo = notification['repository']['full_name']
          type = notification['subject']['type']
          title = notification['subject']['title']
          
          case type
          when 'PullRequest'
            icon = '🔀'
          when 'Issue'
            icon = '📋'
          when 'Release'
            icon = '🚀'
          else
            icon = '📬'
          end
          
          content.add_row("#{icon} #{repo}: #{title}", notification)
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |notification|
    system("open #{notification['subject']['url']}")
  end
end

# Starred repositories updates
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.25; pane.left = 0.5
  pane.title = "Starred Repo Updates"
  pane.highlight = true
  pane.interval = 60 * 15

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get starred repositories
      starred = github.get("/users/#{MY_USERNAME}/starred", { per_page: 10 })
      
      content.add_row("=== Recently Active Starred Repos ===")
      
      starred.each do |repo|
        updated_at = Time.parse(repo['updated_at'])
        days_ago = (Time.now - updated_at) / (24 * 60 * 60)
        
        if days_ago <= 7
          color = 'green'
        elsif days_ago <= 30
          color = 'yellow'
        else
          color = 'white'
        end
        
        content.add_row("[fg=#{color}]#{repo['full_name']}", repo)
        content.add_row("  Updated #{days_ago.round(1)}d ago")
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |repo|
    system("open #{repo['html_url']}")
  end
end

# Contribution graph
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "My Contributions"
  pane.interval = 60 * 30

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get user information
      user = github.get("/users/#{MY_USERNAME}")
      
      content.add_row("=== GitHub Stats ===")
      content.add_row("Public Repos: #{user['public_repos']}")
      content.add_row("Public Gists: #{user['public_gists']}")
      content.add_row("Followers: #{user['followers']}")
      content.add_row("Following: #{user['following']}")
      
      # Get recent commits across all repos
      search_result = github.search("author:#{MY_USERNAME} committer-date:>=#{(Date.today - 30).strftime('%Y-%m-%d')}", type: 'commits')
      
      content.add_row("")
      content.add_row("Commits (last 30 days): #{search_result['total_count']}")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end

# Quick actions
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "Quick Actions"
  pane.highlight = true
  pane.static = true

  pane.content do |content|
    content.add_row("=== Quick Actions ===")
    content.add_row("1. View GitHub Profile", { action: 'profile' })
    content.add_row("2. Open GitHub Dashboard", { action: 'dashboard' })
    content.add_row("3. View My Repositories", { action: 'repos' })
    content.add_row("4. Open GitHub Issues", { action: 'issues' })
    content.add_row("5. Create New Repository", { action: 'new_repo' })
    content.add_row("6. View GitHub Notifications", { action: 'notifications' })
  end
  
  pane.selection do |action_data|
    case action_data[:action]
    when 'profile'
      system("open https://github.com/#{MY_USERNAME}")
    when 'dashboard'
      system("open https://github.com/dashboard")
    when 'repos'
      system("open https://github.com/#{MY_USERNAME}?tab=repositories")
    when 'issues'
      system("open https://github.com/issues")
    when 'new_repo'
      system("open https://github.com/new")
    when 'notifications'
      system("open https://github.com/notifications")
    end
  end
end

# Status summary
add_pane do |pane|
  pane.height = 0.25; pane.width = 1.0; pane.top = 0.75; pane.left = 0
  pane.title = "Status Summary"
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get rate limit status
      status = Wassup::Helpers::GitHub::RateLimiter.status
      
      # Get notifications count
      notifications = github.get("/notifications")
      
      # Get my open PRs
      my_prs = github.search("is:pr is:open author:#{MY_USERNAME}", type: 'issues')
      
      # Get assigned issues
      assigned_issues = github.search("is:issue is:open assignee:#{MY_USERNAME}", type: 'issues')
      
      content.add_row("=== Status Summary ===")
      content.add_row("GitHub API: #{status[:remaining]}/#{status[:limit]} requests")
      content.add_row("Notifications: #{notifications.length}")
      content.add_row("My Open PRs: #{my_prs['total_count']}")
      content.add_row("Assigned Issues: #{assigned_issues['total_count']}")
      
      # Overall status
      if notifications.length > 10
        content.add_row("[fg=yellow]⚠ Many notifications")
      elsif my_prs['total_count'] > 5
        content.add_row("[fg=yellow]⚠ Many open PRs")
      elsif assigned_issues['total_count'] > 10
        content.add_row("[fg=yellow]⚠ Many assigned issues")
      else
        content.add_row("[fg=green]✓ All good!")
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## Next Steps

- [GitHub Setup](./setup.md) - Configure authentication and environment
- [GitHub Helpers](./helpers.md) - Advanced API helpers and utilities
- [GitHub Formatters](./formatters.md) - Custom data formatting options
- [Other Integrations](../netlify/setup.md) - Netlify, CircleCI, and Shortcut examples