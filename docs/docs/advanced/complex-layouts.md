---
sidebar_position: 1
---

# Advanced Configuration

Create sophisticated dashboards with complex layouts, multiple data sources, and advanced features.

## Multi-Pane Dashboards

### Development Team Dashboard

A comprehensive dashboard for software development teams:

```ruby title="Supfile"
# Top row - GitHub activity
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "Open Pull Requests"
  pane.highlight = true
  pane.interval = 60 * 3
  pane.show_refresh = true

  pane.type = Panes::GitHub::PullRequests.new(
    org: ENV['GITHUB_ORG'],
    repo: ENV['GITHUB_REPO'],
    show_username: true,
    show_interactions: true
  )
end

add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "Recent Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: ENV['GITHUB_ORG'],
    repo: ENV['GITHUB_REPO'],
    query: 'is:issue is:open sort:updated-desc',
    show_username: true
  )
end

# Middle row - CI/CD and deployments
add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.3; pane.left = 0
  pane.title = "CI/CD Pipeline"
  pane.highlight = true
  pane.interval = 60 * 2
  pane.alert_level = AlertLevel::MEDIUM

  pane.type = Panes::CircleCI::Workflows.new(
    vcs: 'github',
    org: ENV['GITHUB_ORG'],
    repo: ENV['GITHUB_REPO']
  )
end

add_pane do |pane|
  pane.height = 0.3; pane.width = 0.5; pane.top = 0.3; pane.left = 0.5
  pane.title = "Production Deploys"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::Netlify::Deploys.new(
    site_id: ENV['NETLIFY_SITE_ID']
  )
end

# Bottom row - Project management and metrics
add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0.6; pane.left = 0
  pane.title = "Sprint Progress"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::Shortcut::Stories.new(
    query_pages: {
      "In Progress": 'state:"In Progress"',
      "Ready for Review": 'state:"Ready for Review"',
      "Done This Sprint": 'state:"Done" updated:>-7d'
    }
  )
end
```

### Infrastructure Monitoring Dashboard

Monitor multiple environments and services:

```ruby title="Supfile"
# Environment configuration
ENVIRONMENTS = {
  dev: { color: 'cyan', netlify_id: 'dev-site-id' },
  staging: { color: 'yellow', netlify_id: 'staging-site-id' },
  prod: { color: 'green', netlify_id: 'prod-site-id' }
}

# Top section - Environment health
ENVIRONMENTS.each_with_index do |(env_name, config), index|
  add_pane do |pane|
    pane.height = 0.25; pane.width = 0.33; pane.top = 0; pane.left = index * 0.33
    pane.title = "#{env_name.to_s.capitalize} Health"
    pane.interval = 60

    pane.content do |content|
      # Custom health checks
      endpoints = {
        'API' => "https://api-#{env_name}.example.com/health",
        'Web' => "https://app-#{env_name}.example.com/health",
        'DB' => "https://db-#{env_name}.example.com/health"
      }

      endpoints.each do |service, url|
        begin
          response = `curl -s -o /dev/null -w "%{http_code}" --max-time 5 #{url}`
          case response.to_i
          when 200
            content.add_row("[fg=green]✓ #{service}[fg=white] - Healthy")
          when 0
            content.add_row("[fg=red]✗ #{service}[fg=white] - Timeout")
          else
            content.add_row("[fg=yellow]⚠ #{service}[fg=white] - #{response}")
          end
        rescue => e
          content.add_row("[fg=red]✗ #{service}[fg=white] - Error")
        end
      end
    end
  end
end

# Middle section - Deployment status
add_pane do |pane|
  pane.height = 0.25; pane.width = 1.0; pane.top = 0.25; pane.left = 0
  pane.title = "Recent Deployments"
  pane.highlight = true
  pane.interval = 60 * 3

  pane.content do |content|
    ENVIRONMENTS.each do |env_name, config|
      # Simulate deployment status
      last_deploy = Time.now - rand(3600)
      status = ['success', 'building', 'failed'].sample
      
      case status
      when 'success'
        content.add_row("[fg=green]✓ #{env_name}[fg=white] - Deployed #{time_ago(last_deploy)}")
      when 'building'
        content.add_row("[fg=yellow]⚠ #{env_name}[fg=white] - Building...")
      when 'failed'
        content.add_row("[fg=red]✗ #{env_name}[fg=white] - Failed #{time_ago(last_deploy)}")
      end
    end
  end
end

# Bottom section - System metrics
add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "System Metrics"
  pane.interval = 30

  pane.content do |content|
    # System load
    load_avg = `uptime | grep -o 'load average.*'`.strip
    content.add_row("Load: #{load_avg}")
    
    # Memory usage
    memory = `top -l 1 | grep PhysMem`.strip rescue "Memory info unavailable"
    content.add_row("Memory: #{memory}")
    
    # Disk usage
    disk = `df -h / | tail -1`.strip
    content.add_row("Disk: #{disk}")
    
    # Network connections
    connections = `netstat -an | grep ESTABLISHED | wc -l`.strip
    content.add_row("Connections: #{connections}")
  end
end

add_pane do |pane|
  pane.height = 0.25; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "Alert Summary"
  pane.interval = 60 * 2
  pane.alert_level = AlertLevel::HIGH

  pane.content do |content|
    # Simulate alerts
    alerts = []
    
    # Check system resources
    load = `uptime | grep -o 'load average: [^,]*'`.strip.split(': ')[1].to_f rescue 0
    alerts << { level: 'high', message: 'High system load' } if load > 2.0
    
    # Check disk space
    disk_usage = `df / | tail -1 | awk '{print $5}' | sed 's/%//'`.to_i rescue 0
    alerts << { level: 'medium', message: 'Low disk space' } if disk_usage > 80
    
    if alerts.empty?
      content.add_row("[fg=green]✓ No active alerts")
    else
      alerts.each do |alert|
        color = alert[:level] == 'high' ? 'red' : 'yellow'
        content.add_row("[fg=#{color}]⚠ #{alert[:message]}")
      end
    end
  end
end

# Log monitoring
add_pane do |pane|
  pane.height = 0.25; pane.width = 1.0; pane.top = 0.75; pane.left = 0
  pane.title = "System Logs"
  pane.interval = 30

  pane.content do |content|
    # Monitor various log files
    log_files = [
      '/var/log/system.log',
      '/var/log/kern.log',
      '/usr/local/var/log/nginx/error.log'
    ]
    
    log_files.each do |log_file|
      if File.exist?(log_file)
        recent_logs = `tail -5 #{log_file} 2>/dev/null`.split("\n")
        recent_logs.each do |line|
          next if line.strip.empty?
          
          if line.downcase.include?('error')
            content.add_row("[fg=red]#{File.basename(log_file)}: #{line}")
          elsif line.downcase.include?('warning')
            content.add_row("[fg=yellow]#{File.basename(log_file)}: #{line}")
          else
            content.add_row("#{File.basename(log_file)}: #{line}")
          end
        end
      end
    end
  end
end

# Helper method
def time_ago(time)
  diff = Time.now - time
  case diff
  when 0..59
    "#{diff.to_i}s ago"
  when 60..3599
    "#{(diff / 60).to_i}m ago"
  when 3600..86399
    "#{(diff / 3600).to_i}h ago"
  else
    "#{(diff / 86400).to_i}d ago"
  end
end
```

## Advanced Pane Features

### Multi-Page Content

Create panes with multiple pages of content:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Multi-Service Dashboard"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.content do |content|
    # GitHub page
    begin
      github_prs = fetch_github_data('pull_requests')
      github_prs.each do |pr|
        content.add_row(
          "##{pr['number']} #{pr['title']} (@#{pr['user']['login']})",
          pr,
          page: "GitHub PRs"
        )
      end
    rescue => e
      content.add_row("[fg=red]Error fetching GitHub data: #{e.message}", nil, page: "GitHub PRs")
    end

    # CircleCI page
    begin
      workflows = fetch_circleci_workflows()
      workflows.each do |workflow|
        status_color = workflow['status'] == 'success' ? 'green' : 'red'
        content.add_row(
          "[fg=#{status_color}]#{workflow['name']} - #{workflow['status']}",
          workflow,
          page: "CircleCI"
        )
      end
    rescue => e
      content.add_row("[fg=red]Error fetching CircleCI data: #{e.message}", nil, page: "CircleCI")
    end

    # System metrics page
    content.add_row("Load: #{`uptime | grep -o 'load average.*'`.strip}", nil, page: "System")
    content.add_row("Memory: #{`top -l 1 | grep PhysMem`.strip}", nil, page: "System")
    content.add_row("Disk: #{`df -h / | tail -1`.strip}", nil, page: "System")
  end

  pane.selection do |data|
    if data && data['html_url']
      `open #{data['html_url']}`
    end
  end
end
```

### Custom Selection Actions

Define multiple selection actions with different keys:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Repository Manager"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'myorg',
    repo: 'myrepo',
    show_username: true,
    show_interactions: true
  )

  # Default action (Enter key)
  pane.selection do |pr|
    `open #{pr['html_url']}`
  end

  # Custom actions
  pane.selection('o', 'Open in browser') do |pr|
    `open #{pr['html_url']}`
  end

  pane.selection('c', 'Copy URL') do |pr|
    `echo '#{pr['html_url']}' | pbcopy`
    puts "Copied #{pr['html_url']} to clipboard"
  end

  pane.selection('d', 'Show diff') do |pr|
    `open #{pr['diff_url']}`
  end

  pane.selection('a', 'Approve PR') do |pr|
    # Custom approval workflow
    system("gh pr review #{pr['number']} --approve")
  end
end
```

### Dynamic Content with Error Handling

Create robust panes that handle errors gracefully:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Service Status Monitor"
  pane.interval = 60
  pane.alert_level = AlertLevel::HIGH

  pane.content do |content|
    services = [
      { name: 'API Server', url: 'https://api.example.com/health' },
      { name: 'Database', url: 'https://db.example.com/health' },
      { name: 'Cache', url: 'https://redis.example.com/health' },
      { name: 'Queue', url: 'https://queue.example.com/health' }
    ]

    services.each do |service|
      begin
        # Timeout after 5 seconds
        response = `curl -s -o /dev/null -w "%{http_code}:%{time_total}" --max-time 5 #{service[:url]}`
        code, time = response.split(':')
        
        case code.to_i
        when 200
          content.add_row("[fg=green]✓ #{service[:name]}[fg=white] - OK (#{time}s)")
        when 0
          content.add_row("[fg=red]✗ #{service[:name]}[fg=white] - Timeout")
        else
          content.add_row("[fg=yellow]⚠ #{service[:name]}[fg=white] - HTTP #{code}")
        end
      rescue => e
        content.add_row("[fg=red]✗ #{service[:name]}[fg=white] - Error: #{e.message}")
      end
    end

    # Add summary
    healthy_count = services.count { |s| check_service_health(s[:url]) }
    if healthy_count == services.count
      content.add_row("")
      content.add_row("[fg=green]All services healthy")
    else
      content.add_row("")
      content.add_row("[fg=red]#{services.count - healthy_count} service(s) down")
    end
  end
end

def check_service_health(url)
  response = `curl -s -o /dev/null -w "%{http_code}" --max-time 5 #{url}`
  response.to_i == 200
rescue
  false
end
```

## Performance Optimization

### Caching Expensive Operations

```ruby title="Supfile"
# Global cache
$cache = {}
$cache_ttl = {}

def cached_fetch(key, ttl = 300)
  now = Time.now.to_i
  
  # Check if cache is valid
  if $cache[key] && $cache_ttl[key] && $cache_ttl[key] > now
    return $cache[key]
  end
  
  # Fetch new data
  result = yield
  
  # Cache the result
  $cache[key] = result
  $cache_ttl[key] = now + ttl
  
  result
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Expensive API Data"
  pane.interval = 60

  pane.content do |content|
    # Cache API calls for 5 minutes
    data = cached_fetch('api_data', 300) do
      # Expensive API call
      JSON.parse(`curl -s https://api.example.com/data`)
    end
    
    data.each do |item|
      content.add_row(item['name'], item)
    end
  end
end
```

### Battery-Conscious Updates

```ruby title="Supfile"
def battery_level
  `pmset -g batt | grep -o '[0-9]*%' | sed 's/%//'`.to_i rescue 100
end

def adjust_interval_for_battery(base_interval)
  battery = battery_level
  
  case battery
  when 0..20
    base_interval * 4  # Very slow updates when battery is low
  when 21..50
    base_interval * 2  # Slower updates when battery is medium
  else
    base_interval      # Normal updates when battery is good
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Battery-Conscious Updates"
  pane.interval = adjust_interval_for_battery(60)

  pane.content do |content|
    content.add_row("Battery: #{battery_level}%")
    content.add_row("Update interval: #{pane.interval}s")
    # ... other content
  end
end
```

## Configuration Management

### Environment-Based Configuration

```ruby title="Supfile"
# Load configuration from environment
GITHUB_ORG = ENV['WASSUP_GITHUB_ORG'] || 'defaultorg'
GITHUB_REPO = ENV['WASSUP_GITHUB_REPO'] || 'defaultrepo'
ENVIRONMENT = ENV['WASSUP_ENVIRONMENT'] || 'development'

# Environment-specific settings
CONFIG = {
  'development' => {
    refresh_interval: 30,
    show_debug: true,
    api_timeout: 10
  },
  'production' => {
    refresh_interval: 60,
    show_debug: false,
    api_timeout: 5
  }
}

current_config = CONFIG[ENVIRONMENT]

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub PRs (#{ENVIRONMENT})"
  pane.interval = current_config[:refresh_interval]

  pane.type = Panes::GitHub::PullRequests.new(
    org: GITHUB_ORG,
    repo: GITHUB_REPO,
    show_username: current_config[:show_debug],
    show_interactions: current_config[:show_debug]
  )
end
```

### Modular Configuration

Split large configurations into multiple files:

```ruby title="Supfile"
# Load configuration modules
require_relative 'config/github_panes'
require_relative 'config/system_panes'
require_relative 'config/monitoring_panes'

# GitHub panes
load_github_panes

# System monitoring panes
load_system_panes

# Application monitoring panes
load_monitoring_panes
```

```ruby title="config/github_panes.rb"
def load_github_panes
  add_pane do |pane|
    pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0
    pane.title = "GitHub PRs"
    pane.highlight = true
    pane.interval = 60 * 3

    pane.type = Panes::GitHub::PullRequests.new(
      org: ENV['GITHUB_ORG'],
      repo: ENV['GITHUB_REPO'],
      show_username: true,
      show_interactions: true
    )
  end
end
```

## Next Steps

- [Built-in Integrations](../integrations/github.md) - GitHub, CircleCI, Netlify, and Shortcut
- [Debug Mode](../debug/troubleshooting.md) - Testing and debugging your configurations
- [Helpers & Utilities](../helpers/api-helpers.md) - Custom helpers and utilities