---
sidebar_position: 1
---

# Debug Mode & Troubleshooting

Learn how to debug your Wassup configurations and troubleshoot common issues.

## Debug Mode

Debug mode allows you to test individual panes without running the full dashboard interface.

### How to Use Debug Mode

```bash
# Debug default Supfile
wassup --debug

# Debug specific file
wassup --debug examples/my-config/Supfile
wassup --debug path/to/my/Supfile
```

### What Debug Mode Does

1. **Lists all panes** in your configuration with their titles
2. **Prompts for selection** - choose which pane to test
3. **Runs the selected pane** in isolation
4. **Displays raw output** without the curses interface
5. **Shows errors** with full stack traces

### Debug Mode Example

```bash
$ wassup --debug
1 - GitHub Pull Requests
2 - System Status
3 - CI/CD Pipeline
Choose a pane to run: 2
Going to run: 'System Status'

#########################
# Default
#########################
Hostname: my-laptop.local
Uptime: 10:30  up 2 days, 14:25, 2 users, load averages: 1.52 1.48 1.45
Date: 2024-01-15 10:30:45 -0800
Disk: /dev/disk1s1  233Gi   89Gi  143Gi    39%    /
```

## Testing Individual Panes

### Simple Content Testing

Create a test pane to verify your logic:

```ruby title="debug-test.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Debug Test"
  pane.interval = 1

  pane.content do |content|
    content.add_row("Testing basic content")
    content.add_row("Current time: #{Time.now}")
    
    # Test API call
    begin
      response = `curl -s https://api.github.com/rate_limit`
      content.add_row("API test: #{response[0..50]}...")
    rescue => e
      content.add_row("API error: #{e.message}")
    end
  end
end
```

Run with: `wassup --debug debug-test.rb`

### Testing GitHub Integration

```ruby title="github-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Debug"
  pane.interval = 60

  pane.content do |content|
    content.add_row("GitHub Username: #{ENV['WASSUP_GITHUB_USERNAME']}")
    content.add_row("GitHub Token: #{ENV['WASSUP_GITHUB_ACCESS_TOKEN'] ? 'Set' : 'Not set'}")
    
    # Test rate limit
    begin
      rate_limit = Wassup::Helpers::GitHub::RateLimiter.status
      content.add_row("Rate limit remaining: #{rate_limit[:remaining]}")
      content.add_row("Rate limit reset: #{rate_limit[:reset_at]}")
    rescue => e
      content.add_row("Rate limit error: #{e.message}")
    end
  end
end
```

### Testing Built-in Pane Types

```ruby title="pane-type-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub PRs Debug"
  pane.interval = 60

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',  # Use a public repo for testing
    repo: 'rails',
    show_username: true,
    show_interactions: true
  )
end
```

## Troubleshooting Common Issues

### Authentication Problems

#### GitHub Authentication

```bash
# Check if environment variables are set
echo $WASSUP_GITHUB_USERNAME
echo $WASSUP_GITHUB_ACCESS_TOKEN

# Test token validity
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/user
```

**Common fixes:**
- Ensure token has correct scopes (`repo`, `public_repo`, `user`)
- Check token hasn't expired
- Verify username matches the token

#### CircleCI Authentication

```bash
# Check token
echo $WASSUP_CIRCLE_CI_API_TOKEN

# Test token
curl -H "Circle-Token: $WASSUP_CIRCLE_CI_API_TOKEN" https://circleci.com/api/v2/me
```

#### Netlify Authentication

```bash
# Check token
echo $WASSUP_NETLIFY_TOKEN

# Test token
curl -H "Authorization: Bearer $WASSUP_NETLIFY_TOKEN" https://api.netlify.com/api/v1/user
```

### Rate Limiting Issues

#### Check Rate Limit Status

Create a debug pane to monitor rate limits:

```ruby title="rate-limit-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Rate Limit Status"
  pane.interval = 60

  pane.content do |content|
    begin
      # GitHub rate limit
      status = Wassup::Helpers::GitHub::RateLimiter.status
      content.add_row("=== GitHub Rate Limits ===")
      content.add_row("Remaining: #{status[:remaining]}/#{status[:limit]}")
      content.add_row("Reset at: #{status[:reset_at]}")
      content.add_row("Search remaining: #{status[:search_remaining]}")
      content.add_row("Search reset at: #{status[:search_reset_at]}")
      content.add_row("Queue size: #{status[:queue_size]}")
      content.add_row("Worker running: #{status[:running]}")
      content.add_row("Current requests: #{status[:current_requests]}")
      
      if status[:last_error]
        content.add_row("Last error: #{status[:last_error]}")
      end
    rescue => e
      content.add_row("Error getting rate limit: #{e.message}")
    end
  end
end
```

#### Rate Limit Solutions

1. **Increase refresh intervals**:
   ```ruby
   pane.interval = 60 * 5  # 5 minutes instead of 1 minute
   ```

2. **Use fewer panes** with GitHub integration

3. **Combine queries** using search instead of multiple panes

4. **Check for rate limit errors**:
   ```ruby
   pane.content do |content|
     begin
       # Your API call
     rescue => e
       if e.message.include?('rate limit')
         content.add_row("[fg=red]Rate limit exceeded")
       else
         content.add_row("[fg=red]Error: #{e.message}")
       end
     end
   end
   ```

### Terminal and Display Issues

#### Terminal Size Problems

```ruby title="terminal-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Terminal Debug"
  pane.interval = 5

  pane.content do |content|
    # Terminal dimensions
    rows, cols = `stty size`.split.map(&:to_i)
    content.add_row("Terminal size: #{cols}x#{rows}")
    
    # Test if terminal is too small
    if cols < 80 || rows < 24
      content.add_row("[fg=red]Warning: Terminal may be too small")
    end
    
    # Environment info
    content.add_row("TERM: #{ENV['TERM']}")
    content.add_row("COLORTERM: #{ENV['COLORTERM']}")
  end
end
```

#### Color Display Issues

```ruby title="color-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Color Test"
  pane.interval = 60

  pane.content do |content|
    colors = %w[red green yellow blue cyan magenta white]
    colors.each do |color|
      content.add_row("[fg=#{color}]#{color.capitalize} text")
    end
    content.add_row("Normal text")
  end
end
```

### Configuration Errors

#### Syntax Errors

```bash
# Check Ruby syntax
ruby -c Supfile

# Check for common issues
ruby -e "
  require 'wassup'
  load 'Supfile'
  puts 'Configuration loaded successfully'
"
```

#### Missing Dependencies

```ruby title="dependency-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Dependency Check"
  pane.interval = 60

  pane.content do |content|
    # Check required gems
    gems = %w[curses json rest-client]
    gems.each do |gem_name|
      begin
        require gem_name
        content.add_row("[fg=green]✓ #{gem_name}")
      rescue LoadError
        content.add_row("[fg=red]✗ #{gem_name} - Not installed")
      end
    end
    
    # Check environment variables
    env_vars = %w[WASSUP_GITHUB_USERNAME WASSUP_GITHUB_ACCESS_TOKEN]
    env_vars.each do |var|
      if ENV[var]
        content.add_row("[fg=green]✓ #{var}")
      else
        content.add_row("[fg=yellow]⚠ #{var} - Not set")
      end
    end
  end
end
```

### Performance Issues

#### Slow Loading

```ruby title="performance-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Performance Test"
  pane.interval = 60

  pane.content do |content|
    start_time = Time.now
    
    # Simulate API call
    sleep(0.1)
    
    end_time = Time.now
    duration = end_time - start_time
    
    content.add_row("Content generation time: #{duration.round(2)}s")
    
    if duration > 5
      content.add_row("[fg=red]Warning: Slow content generation")
    elsif duration > 2
      content.add_row("[fg=yellow]Moderate content generation time")
    else
      content.add_row("[fg=green]Good content generation time")
    end
  end
end
```

## Advanced Debugging

### Custom Error Handling

```ruby title="error-handling-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Error Handling Test"
  pane.interval = 60

  pane.content do |content|
    begin
      # Simulate different types of errors
      case rand(4)
      when 0
        raise StandardError, "Generic error"
      when 1
        raise Net::ReadTimeout, "Network timeout"
      when 2
        raise JSON::ParserError, "Invalid JSON"
      when 3
        # Success case
        content.add_row("[fg=green]✓ No errors")
      end
    rescue Net::ReadTimeout => e
      content.add_row("[fg=yellow]⚠ Network timeout - retrying later")
    rescue JSON::ParserError => e
      content.add_row("[fg=red]✗ Invalid data format")
    rescue => e
      content.add_row("[fg=red]✗ Unexpected error: #{e.class}")
      content.add_row("   #{e.message}")
    end
  end
end
```

### Memory Usage Monitoring

```ruby title="memory-debug.rb"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Memory Usage"
  pane.interval = 30

  pane.content do |content|
    # Get memory usage
    memory_info = `ps -o pid,vsz,rss,comm -p #{Process.pid}`.split("\n")[1]
    content.add_row("Process info: #{memory_info}")
    
    # Ruby memory usage
    content.add_row("Ruby objects: #{GC.stat[:heap_live_slots]}")
    content.add_row("GC runs: #{GC.stat[:count]}")
    
    # Force garbage collection for testing
    GC.start
    content.add_row("GC forced - objects now: #{GC.stat[:heap_live_slots]}")
  end
end
```

## Getting Help

### Debug Information to Include

When asking for help, include:

1. **Wassup version**: `gem list wassup`
2. **Ruby version**: `ruby -v`
3. **Operating system**: `uname -a`
4. **Terminal**: `echo $TERM`
5. **Error output**: Copy from debug mode
6. **Configuration**: Relevant Supfile sections

### Common Support Commands

```bash
# Version information
gem list wassup
ruby -v
uname -a

# Test basic functionality
wassup --debug

# Check environment
env | grep WASSUP

# Network connectivity
curl -s https://api.github.com/zen
```

## Next Steps

- [Simple Configuration](../basics/simple-configuration.md) - Go back to basics
- [Advanced Configuration](../advanced/complex-layouts.md) - Complex layouts and features
- [Helpers & Utilities](../helpers/api-helpers.md) - Custom helpers and utilities