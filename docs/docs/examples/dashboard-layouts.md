---
sidebar_position: 1
---

# Dashboard Layouts

This guide provides real-world examples of dashboard layouts for different use cases.

## Software Development Team Dashboard

Perfect for development teams monitoring code, deployments, and project status.

```ruby title="Supfile"
# Top row - GitHub activity
add_pane do |pane|
  pane.height = 0.4; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "Team Pull Requests"
  pane.highlight = true
  pane.interval = 60 * 3

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:pr is:open author:teammate1 author:teammate2 author:teammate3',
    show_repo: true,
    show_username: true,
    show_interactions: true
  )
end

add_pane do |pane|
  pane.height = 0.4; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "Recent Releases"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::GitHub::Releases.new(
    org: 'myorg',
    repo: 'main-product'
  )
end

# Middle row - CI/CD status
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.4; pane.left = 0
  pane.title = "CI/CD Pipeline"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.type = Panes::CircleCI::Workflows.new(
    vcs: 'github',
    org: 'myorg',
    repo: 'main-product'
  )
end

add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.4; pane.left = 0.5
  pane.title = "Production Deploys"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::Netlify::Deploys.new(
    site_id: 'production-site-id'
  )
end

# Bottom row - Project management
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0.7; pane.left = 0
  pane.title = "Sprint Progress"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::Shortcut::Stories.new(
    query_pages: {
      "In Progress": 'state:"In Progress"',
      "Ready for Review": 'state:"Ready for Review"',
      "Done": 'state:"Done" updated:>-7d'
    }
  )
end
```

## DevOps Monitoring Dashboard

Focused on system health, deployments, and infrastructure monitoring.

```ruby title="Supfile"
# Top section - System health
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.33; pane.top = 0; pane.left = 0
  pane.title = "System Load"
  pane.interval = 30

  pane.content do |content|
    uptime = `uptime`.strip
    load_avg = uptime.match(/load average: (.+)$/)[1]
    memory = `free -h | grep '^Mem'`
    disk = `df -h | grep -v tmpfs | grep -v udev`

    content.add_row("Load: #{load_avg}")
    content.add_row("Memory: #{memory}")
    content.add_row("Disk usage:")
    disk.split("\n").each do |line|
      content.add_row("  #{line}")
    end
  end
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.33; pane.top = 0; pane.left = 0.33
  pane.title = "Docker Containers"
  pane.interval = 60

  pane.content do |content|
    containers = `docker ps --format "table {{.Names}}\t{{.Status}}"`.split("\n")[1..-1]
    containers.each do |container|
      name, status = container.split("\t")
      color = status.include?("Up") ? "green" : "red"
      content.add_row("[fg=#{color}]#{name}[fg=white] - #{status}")
    end
  end
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.34; pane.top = 0; pane.left = 0.66
  pane.title = "Network Status"
  pane.interval = 60

  pane.content do |content|
    # Ping critical services
    services = ['google.com', 'github.com', 'api.example.com']
    services.each do |service|
      ping = `ping -c 1 #{service} 2>&1`
      if ping.include?("1 packets transmitted, 1 received")
        content.add_row("[fg=green]#{service}[fg=white] - OK")
      else
        content.add_row("[fg=red]#{service}[fg=white] - FAIL")
      end
    end
  end
end

# Middle section - Deployment status
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.25; pane.left = 0
  pane.title = "Production Deploys"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::Netlify::Deploys.new(
    site_id: 'prod-site-id'
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.25; pane.left = 0.5
  pane.title = "Staging Deploys"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::Netlify::Deploys.new(
    site_id: 'staging-site-id'
  )
end

# Bottom section - CI/CD and issues
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "Build Status"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.type = Panes::CircleCI::Workflows.new(
    vcs: 'github',
    org: 'myorg',
    repo: 'infrastructure'
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "Critical Issues"
  pane.highlight = true
  pane.interval = 60 * 5
  pane.alert_level = AlertLevel::HIGH

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:issue is:open label:critical',
    show_repo: true,
    show_username: true
  )
end

# Log monitoring
add_pane do |pane|
  pane.height = 0.25; pane.width = 1.0; pane.top = 0.75; pane.left = 0
  pane.title = "Recent Logs"
  pane.interval = 30

  pane.content do |content|
    # Tail recent application logs
    logs = `tail -n 20 /var/log/app.log 2>/dev/null || echo "No logs found"`
    logs.split("\n").each do |line|
      if line.include?("ERROR")
        content.add_row("[fg=red]#{line}")
      elsif line.include?("WARN")
        content.add_row("[fg=yellow]#{line}")
      else
        content.add_row(line)
      end
    end
  end
end
```

## Personal Productivity Dashboard

Track your personal projects, tasks, and goals.

```ruby title="Supfile"
# Top section - Today's focus
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "Today's Tasks"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::Shortcut::Stories.new(
    query: 'owner:@me state:"In Progress"'
  )
end

add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "My Pull Requests"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:pr is:open author:@me',
    show_repo: true,
    show_interactions: true
  )
end

# Middle section - Project status
add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0.3; pane.left = 0
  pane.title = "Project Progress"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::Shortcut::Stories.new(
    query_pages: {
      "Active": 'owner:@me state:"In Progress"',
      "Review": 'owner:@me state:"Ready for Review"',
      "Blocked": 'owner:@me state:"Blocked"',
      "Completed": 'owner:@me state:"Done" updated:>-7d'
    }
  )
end

# Bottom section - System info and notes
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.7; pane.left = 0
  pane.title = "System Status"
  pane.interval = 60

  pane.content do |content|
    # System metrics
    uptime = `uptime`.strip
    battery = `pmset -g batt | grep -o '[0-9]*%'` rescue "N/A"
    wifi = `iwgetid -r` rescue "N/A"

    content.add_row("Uptime: #{uptime}")
    content.add_row("Battery: #{battery}")
    content.add_row("WiFi: #{wifi}")
    
    # Git status for current project
    if Dir.exist?('.git')
      branch = `git branch --show-current`.strip
      status = `git status --porcelain`.strip
      content.add_row("Git branch: #{branch}")
      content.add_row("Changes: #{status.empty? ? 'Clean' : status.lines.count}")
    end
  end
end

add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.7; pane.left = 0.5
  pane.title = "Quick Notes"
  pane.interval = 60 * 30

  pane.content do |content|
    # Read from a notes file
    notes_file = File.expand_path('~/.wassup-notes')
    if File.exist?(notes_file)
      File.readlines(notes_file).each do |line|
        content.add_row(line.strip)
      end
    else
      content.add_row("No notes found")
      content.add_row("Create ~/.wassup-notes to add notes")
    end
  end
end
```

## Open Source Maintainer Dashboard

Monitor your open source projects, contributions, and community activity.

```ruby title="Supfile"
# Top section - Repository activity
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "New Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:issue is:open sort:created-desc',
    show_repo: true,
    show_username: true
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "Community PRs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:pr is:open -author:@me',
    show_repo: true,
    show_username: true,
    show_interactions: true
  )
end

# Second row - Specific repositories
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.33; pane.top = 0.25; pane.left = 0
  pane.title = "Main Project PRs"
  pane.highlight = true
  pane.interval = 60 * 3

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'myorg',
    repo: 'main-project',
    show_username: true,
    show_interactions: true
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.33; pane.top = 0.25; pane.left = 0.33
  pane.title = "Library Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    repo: 'my-library',
    query: 'is:issue is:open',
    show_username: true
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.34; pane.top = 0.25; pane.left = 0.66
  pane.title = "Documentation PRs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:pr is:open label:documentation',
    show_repo: true,
    show_username: true
  )
end

# Third row - Community and maintenance
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "Bug Reports"
  pane.highlight = true
  pane.interval = 60 * 5
  pane.alert_level = AlertLevel::MEDIUM

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:issue is:open label:bug',
    show_repo: true,
    show_username: true
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "Feature Requests"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:issue is:open label:enhancement',
    show_repo: true,
    show_username: true
  )
end

# Bottom section - Release management
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.75; pane.left = 0
  pane.title = "Recent Releases"
  pane.highlight = true
  pane.interval = 60 * 15

  pane.type = Panes::GitHub::Releases.new(
    org: 'myorg',
    repo: 'main-project'
  )
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.75; pane.left = 0.5
  pane.title = "CI Status"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.type = Panes::CircleCI::Workflows.new(
    vcs: 'github',
    org: 'myorg',
    repo: 'main-project'
  )
end
```

## Multi-Environment Monitoring

Track multiple environments (development, staging, production) across different services.

```ruby title="Supfile"
# Environment status overview
environments = [
  { name: 'Development', netlify_id: 'dev-site-id', color: 'cyan' },
  { name: 'Staging', netlify_id: 'staging-site-id', color: 'yellow' },
  { name: 'Production', netlify_id: 'prod-site-id', color: 'green' }
]

environments.each_with_index do |env, index|
  # Deployment status
  add_pane do |pane|
    pane.height = 0.33; pane.width = 0.33; pane.top = 0; pane.left = index * 0.33
    pane.title = "#{env[:name]} Deploys"
    pane.highlight = true
    pane.interval = 60 * 3

    pane.type = Panes::Netlify::Deploys.new(
      site_id: env[:netlify_id]
    )
  end

  # Environment-specific issues
  add_pane do |pane|
    pane.height = 0.33; pane.width = 0.33; pane.top = 0.33; pane.left = index * 0.33
    pane.title = "#{env[:name]} Issues"
    pane.highlight = true
    pane.interval = 60 * 5

    pane.type = Panes::GitHub::Search.new(
      org: 'myorg',
      query: "is:issue is:open label:#{env[:name].downcase}",
      show_repo: true
    )
  end

  # Custom health checks
  add_pane do |pane|
    pane.height = 0.34; pane.width = 0.33; pane.top = 0.66; pane.left = index * 0.33
    pane.title = "#{env[:name]} Health"
    pane.interval = 60 * 2

    pane.content do |content|
      # Health check endpoints
      endpoints = {
        'API' => "https://api-#{env[:name].downcase}.example.com/health",
        'Web' => "https://app-#{env[:name].downcase}.example.com/health",
        'DB' => "https://db-#{env[:name].downcase}.example.com/health"
      }

      endpoints.each do |service, url|
        begin
          response = `curl -s -o /dev/null -w "%{http_code}" #{url}`
          if response.to_i == 200
            content.add_row("[fg=green]#{service}[fg=white] - OK")
          else
            content.add_row("[fg=red]#{service}[fg=white] - #{response}")
          end
        rescue
          content.add_row("[fg=red]#{service}[fg=white] - ERROR")
        end
      end
    end
  end
end
```

## Layout Tips

### Responsive Design
- Use relative positioning (0.0 to 1.0) for flexibility
- Test layouts at different terminal sizes
- Consider minimum terminal dimensions

### Performance Optimization
- Use appropriate refresh intervals
- Batch related API calls
- Cache expensive operations
- Monitor rate limits

### Visual Hierarchy
- Use alert levels for priority
- Group related information
- Use color coding consistently
- Provide clear pane titles

### Interactive Features
- Enable highlighting for actionable items
- Provide multiple selection options
- Use meaningful key bindings
- Include help descriptions

## Next Steps

- [Configuration Reference](../configuration/pane-properties.md)
- [GitHub Integration](../integrations/github.md)
- [Keyboard Controls](../usage/keyboard-controls.md)
- [Troubleshooting](../troubleshooting/common-issues.md)