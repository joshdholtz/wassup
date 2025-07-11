---
sidebar_position: 3
---

# GitHub Formatters

Specialized formatters for displaying GitHub data with consistent styling and formatting.

## GitHub-Specific Formatters

### Pull Request Formatter

```ruby title="Supfile"
class GitHubPRFormatter
  def self.format_pr(pr, options = {})
    parts = []
    
    # PR number and title
    parts << "##{pr['number']}"
    parts << pr['title']
    
    # Author information
    if options[:show_author]
      parts << "(@#{pr['user']['login']})"
    end
    
    # Interaction counts
    if options[:show_interactions]
      interactions = []
      if pr['comments'] && pr['comments'] > 0
        interactions << "💬 #{pr['comments']}"
      end
      if pr['review_comments'] && pr['review_comments'] > 0
        interactions << "📝 #{pr['review_comments']}"
      end
      if pr['reactions'] && pr['reactions']['total_count'] > 0
        interactions << "👍 #{pr['reactions']['total_count']}"
      end
      parts << "(#{interactions.join(' ')})" unless interactions.empty?
    end
    
    # Status color coding
    if options[:colorize]
      case pr['state']
      when 'open'
        if pr['draft']
          "[fg=cyan]#{parts.join(' ')} [DRAFT]"
        else
          "[fg=green]#{parts.join(' ')}"
        end
      when 'closed'
        if pr['merged_at']
          "[fg=blue]#{parts.join(' ')} [MERGED]"
        else
          "[fg=red]#{parts.join(' ')} [CLOSED]"
        end
      else
        parts.join(' ')
      end
    else
      parts.join(' ')
    end
  end
  
  def self.format_pr_list(prs, options = {})
    prs.map { |pr| format_pr(pr, options) }
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Formatted GitHub PRs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      prs = github.get("/repos/rails/rails/pulls", { state: 'open', per_page: 10 })
      
      content.add_row("=== Open Pull Requests ===")
      
      formatted_prs = GitHubPRFormatter.format_pr_list(prs, {
        show_author: true,
        show_interactions: true,
        colorize: true
      })
      
      formatted_prs.each_with_index do |formatted_pr, index|
        content.add_row(formatted_pr, prs[index])
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |pr|
    `open #{pr['html_url']}`
  end
end
```

### Issue Formatter

```ruby title="Supfile"
class GitHubIssueFormatter
  def self.format_issue(issue, options = {})
    parts = []
    
    # Issue number and title
    parts << "##{issue['number']}"
    parts << issue['title']
    
    # Labels
    if options[:show_labels] && issue['labels'] && !issue['labels'].empty?
      labels = issue['labels'].map { |label| label['name'] }.join(', ')
      parts << "[#{labels}]"
    end
    
    # Author
    if options[:show_author]
      parts << "(@#{issue['user']['login']})"
    end
    
    # Comments and reactions
    if options[:show_interactions]
      interactions = []
      if issue['comments'] && issue['comments'] > 0
        interactions << "💬 #{issue['comments']}"
      end
      if issue['reactions'] && issue['reactions']['total_count'] > 0
        interactions << "👍 #{issue['reactions']['total_count']}"
      end
      parts << "(#{interactions.join(' ')})" unless interactions.empty?
    end
    
    # Assignee
    if options[:show_assignee] && issue['assignee']
      parts << "→ #{issue['assignee']['login']}"
    end
    
    # Status and priority color coding
    if options[:colorize]
      # Determine color based on labels and state
      color = case issue['state']
      when 'open'
        if issue['labels']&.any? { |l| l['name'].downcase.include?('bug') }
          'red'
        elsif issue['labels']&.any? { |l| l['name'].downcase.include?('enhancement') }
          'green'
        elsif issue['labels']&.any? { |l| l['name'].downcase.include?('question') }
          'cyan'
        else
          'yellow'
        end
      when 'closed'
        'white'
      else
        'white'
      end
      
      "[fg=#{color}]#{parts.join(' ')}"
    else
      parts.join(' ')
    end
  end
  
  def self.format_issue_summary(issues)
    summary = {
      total: issues.length,
      bugs: 0,
      enhancements: 0,
      questions: 0,
      other: 0
    }
    
    issues.each do |issue|
      labels = issue['labels']&.map { |l| l['name'].downcase } || []
      
      if labels.any? { |l| l.include?('bug') }
        summary[:bugs] += 1
      elsif labels.any? { |l| l.include?('enhancement') || l.include?('feature') }
        summary[:enhancements] += 1
      elsif labels.any? { |l| l.include?('question') }
        summary[:questions] += 1
      else
        summary[:other] += 1
      end
    end
    
    summary
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Issues Dashboard"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      issues = github.get("/repos/rails/rails/issues", { 
        state: 'open', 
        per_page: 15,
        sort: 'updated',
        direction: 'desc'
      })
      
      # Summary
      summary = GitHubIssueFormatter.format_issue_summary(issues)
      content.add_row("=== Issue Summary ===")
      content.add_row("Total: #{summary[:total]}")
      content.add_row("[fg=red]🐛 Bugs: #{summary[:bugs]}")
      content.add_row("[fg=green]✨ Enhancements: #{summary[:enhancements]}")
      content.add_row("[fg=cyan]❓ Questions: #{summary[:questions]}")
      content.add_row("[fg=yellow]📋 Other: #{summary[:other]}")
      content.add_row("")
      
      # Recent issues
      content.add_row("=== Recent Issues ===")
      issues[0, 10].each do |issue|
        formatted_issue = GitHubIssueFormatter.format_issue(issue, {
          show_labels: true,
          show_author: true,
          show_interactions: true,
          colorize: true
        })
        content.add_row(formatted_issue, issue)
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |issue|
    `open #{issue['html_url']}`
  end
end
```

### Repository Formatter

```ruby title="Supfile"
class GitHubRepoFormatter
  def self.format_repo_stats(repo, options = {})
    parts = []
    
    # Repository name
    parts << repo['full_name']
    
    # Statistics
    if options[:show_stats]
      stats = []
      stats << "⭐ #{format_number(repo['stargazers_count'])}"
      stats << "🍴 #{format_number(repo['forks_count'])}"
      if repo['open_issues_count'] > 0
        stats << "📋 #{format_number(repo['open_issues_count'])}"
      end
      parts << "(#{stats.join(' ')})"
    end
    
    # Language
    if options[:show_language] && repo['language']
      parts << "[#{repo['language']}]"
    end
    
    # Last update
    if options[:show_last_update]
      updated_at = Time.parse(repo['updated_at'])
      time_ago = format_time_ago(updated_at)
      parts << "updated #{time_ago}"
    end
    
    # Description
    if options[:show_description] && repo['description']
      description = repo['description'].length > 60 ? 
        "#{repo['description'][0, 57]}..." : 
        repo['description']
      parts << "- #{description}"
    end
    
    # Color coding based on activity
    if options[:colorize]
      updated_at = Time.parse(repo['updated_at'])
      days_ago = (Time.now - updated_at) / (24 * 60 * 60)
      
      color = case days_ago
      when 0..7 then 'green'      # Updated within a week
      when 8..30 then 'yellow'    # Updated within a month
      when 31..90 then 'cyan'     # Updated within 3 months
      else 'white'                # Older updates
      end
      
      "[fg=#{color}]#{parts.join(' ')}"
    else
      parts.join(' ')
    end
  end
  
  def self.format_number(num)
    case num
    when 0..999
      num.to_s
    when 1000..999_999
      "#{(num / 1000.0).round(1)}k"
    when 1_000_000..999_999_999
      "#{(num / 1_000_000.0).round(1)}m"
    else
      "#{(num / 1_000_000_000.0).round(1)}b"
    end
  end
  
  def self.format_time_ago(time)
    diff = Time.now - time
    
    case diff
    when 0..3599
      "#{(diff / 60).to_i}m ago"
    when 3600..86399
      "#{(diff / 3600).to_i}h ago"
    when 86400..2591999
      "#{(diff / 86400).to_i}d ago"
    else
      time.strftime("%b %d, %Y")
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Repository Explorer"
  pane.highlight = true
  pane.interval = 60 * 15

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      
      # Search for popular Ruby repositories
      search_results = github.search("language:ruby stars:>1000", type: 'repositories')
      
      content.add_row("=== Popular Ruby Repositories ===")
      
      search_results['items'][0, 10].each do |repo|
        formatted_repo = GitHubRepoFormatter.format_repo_stats(repo, {
          show_stats: true,
          show_language: true,
          show_last_update: true,
          show_description: true,
          colorize: true
        })
        content.add_row(formatted_repo, repo)
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |repo|
    `open #{repo['html_url']}`
  end
end
```

### Release Formatter

```ruby title="Supfile"
class GitHubReleaseFormatter
  def self.format_release(release, options = {})
    parts = []
    
    # Version/tag name
    parts << release['tag_name']
    
    # Release name if different from tag
    if options[:show_name] && release['name'] && release['name'] != release['tag_name']
      parts << "\"#{release['name']}\""
    end
    
    # Publication date
    if options[:show_date]
      published_at = Time.parse(release['published_at'])
      parts << "#{GitHubRepoFormatter.format_time_ago(published_at)}"
    end
    
    # Download count
    if options[:show_downloads] && release['assets']
      total_downloads = release['assets'].sum { |asset| asset['download_count'] }
      if total_downloads > 0
        parts << "↓ #{GitHubRepoFormatter.format_number(total_downloads)}"
      end
    end
    
    # Pre-release and draft indicators
    status_indicators = []
    status_indicators << "DRAFT" if release['draft']
    status_indicators << "PRE-RELEASE" if release['prerelease']
    
    if status_indicators.any?
      parts << "[#{status_indicators.join(', ')}]"
    end
    
    # Color coding
    if options[:colorize]
      color = if release['draft']
        'cyan'
      elsif release['prerelease']
        'yellow'
      else
        'green'
      end
      
      "[fg=#{color}]#{parts.join(' ')}"
    else
      parts.join(' ')
    end
  end
  
  def self.format_release_notes(release, max_lines = 3)
    return [] unless release['body']
    
    lines = release['body'].split("\n").reject(&:empty?)
    
    # Take first few lines and truncate if needed
    preview_lines = lines[0, max_lines]
    
    if lines.length > max_lines
      preview_lines << "... (#{lines.length - max_lines} more lines)"
    end
    
    preview_lines
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Releases"
  pane.highlight = true
  pane.interval = 60 * 20

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      releases = github.get("/repos/rails/rails/releases", { per_page: 8 })
      
      content.add_row("=== Recent Releases ===")
      
      releases.each do |release|
        # Main release info
        formatted_release = GitHubReleaseFormatter.format_release(release, {
          show_name: true,
          show_date: true,
          show_downloads: true,
          colorize: true
        })
        content.add_row(formatted_release, release)
        
        # Release notes preview
        if release['body'] && !release['body'].empty?
          notes = GitHubReleaseFormatter.format_release_notes(release, 2)
          notes.each do |line|
            content.add_row("  #{line}")
          end
        end
        
        content.add_row("")
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |release|
    `open #{release['html_url']}`
  end
end
```

## Advanced GitHub Formatters

### Activity Timeline Formatter

```ruby title="Supfile"
class GitHubActivityFormatter
  def self.format_activity_timeline(events, options = {})
    formatted_events = []
    
    events.each do |event|
      case event['type']
      when 'PushEvent'
        commits = event['payload']['commits']
        repo = event['repo']['name']
        formatted_events << {
          type: 'push',
          text: "[fg=green]📤 Pushed #{commits.length} commit(s) to #{repo}",
          time: event['created_at'],
          data: event
        }
        
      when 'PullRequestEvent'
        action = event['payload']['action']
        pr = event['payload']['pull_request']
        repo = event['repo']['name']
        formatted_events << {
          type: 'pr',
          text: "[fg=blue]🔀 #{action.capitalize} PR ##{pr['number']} in #{repo}",
          time: event['created_at'],
          data: event
        }
        
      when 'IssuesEvent'
        action = event['payload']['action']
        issue = event['payload']['issue']
        repo = event['repo']['name']
        formatted_events << {
          type: 'issue',
          text: "[fg=yellow]📋 #{action.capitalize} issue ##{issue['number']} in #{repo}",
          time: event['created_at'],
          data: event
        }
        
      when 'CreateEvent'
        ref_type = event['payload']['ref_type']
        repo = event['repo']['name']
        formatted_events << {
          type: 'create',
          text: "[fg=cyan]✨ Created #{ref_type} in #{repo}",
          time: event['created_at'],
          data: event
        }
        
      when 'WatchEvent'
        repo = event['repo']['name']
        formatted_events << {
          type: 'star',
          text: "[fg=yellow]⭐ Starred #{repo}",
          time: event['created_at'],
          data: event
        }
      end
    end
    
    # Sort by time (most recent first)
    formatted_events.sort_by { |e| Time.parse(e[:time]) }.reverse
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Activity Timeline"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      
      # Get recent public events for a user
      events = github.get("/users/dhh/events/public", { per_page: 20 })
      
      timeline = GitHubActivityFormatter.format_activity_timeline(events)
      
      content.add_row("=== Recent Activity ===")
      
      timeline[0, 15].each do |activity|
        time_ago = GitHubRepoFormatter.format_time_ago(Time.parse(activity[:time]))
        content.add_row("#{activity[:text]} (#{time_ago})", activity[:data])
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end

  pane.selection do |event|
    if event['repo']
      `open https://github.com/#{event['repo']['name']}`
    end
  end
end
```

### Trend Formatter

```ruby title="Supfile"
class GitHubTrendFormatter
  def self.format_trending_repositories(repos)
    repos.map.with_index do |repo, index|
      # Rank indicator
      rank = "#{index + 1}."
      
      # Repository info
      name = repo['full_name']
      
      # Statistics with trends
      stars = repo['stargazers_count']
      stars_today = repo['stargazers_count'] # This would be calculated from API
      
      # Language
      language = repo['language'] ? "[#{repo['language']}]" : ""
      
      # Trend indicator (would calculate from historical data)
      trend = "📈"  # Simplified - would show actual trend
      
      "[fg=green]#{rank} #{name} #{language} ⭐ #{GitHubRepoFormatter.format_number(stars)} #{trend}"
    end
  end
end
```

## Utility Functions

### GitHub Color Themes

```ruby title="Supfile"
module GitHubColorTheme
  COLORS = {
    # PR states
    pr_open: 'green',
    pr_draft: 'cyan',
    pr_merged: 'blue',
    pr_closed: 'red',
    
    # Issue types
    issue_bug: 'red',
    issue_enhancement: 'green',
    issue_question: 'cyan',
    issue_other: 'yellow',
    
    # Repository activity
    repo_active: 'green',      # Updated < 1 week
    repo_moderate: 'yellow',   # Updated < 1 month
    repo_stale: 'cyan',        # Updated < 3 months
    repo_inactive: 'white',    # Updated > 3 months
    
    # General
    success: 'green',
    warning: 'yellow',
    error: 'red',
    info: 'blue',
    muted: 'white'
  }
  
  def self.colorize(text, color_key)
    color = COLORS[color_key] || COLORS[:muted]
    "[fg=#{color}]#{text}"
  end
end
```

## Next Steps

- [GitHub Examples](./examples.md) - Real-world GitHub dashboard configurations
- [GitHub Helpers](./helpers.md) - Advanced GitHub API utilities
- [Other Integrations](../netlify/setup.md) - Netlify, CircleCI, and Shortcut integrations