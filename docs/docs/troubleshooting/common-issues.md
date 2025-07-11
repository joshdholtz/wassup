---
sidebar_position: 1
---

# Common Issues

Solutions to frequently encountered problems when using Wassup.

## Installation Issues

### Ruby Version Compatibility

**Problem**: Wassup fails to install or run due to Ruby version mismatch.

**Solution**:
```bash
# Check your Ruby version
ruby -v

# Wassup requires Ruby 2.7 or higher
# Install Ruby via rbenv (recommended)
rbenv install 3.0.0
rbenv global 3.0.0

# Or use RVM
rvm install 3.0.0
rvm use 3.0.0 --default
```

### Gem Installation Failures

**Problem**: `gem install wassup` fails with compilation errors.

**Solution**:
```bash
# Install development dependencies
# On macOS:
xcode-select --install

# On Ubuntu/Debian:
sudo apt-get install build-essential

# On CentOS/RHEL:
sudo yum groupinstall "Development Tools"

# Then retry installation
gem install wassup
```

### Permission Errors

**Problem**: Permission denied when installing gems.

**Solution**:
```bash
# Don't use sudo - use a Ruby version manager instead
# If you must use system Ruby, install to user directory
gem install wassup --user-install

# Or use bundler with local installation
bundle install --path vendor/bundle
```

## Configuration Issues

### Missing Environment Variables

**Problem**: Integrations fail with authentication errors.

**Solution**:
```bash
# Create a .env file in your project directory
touch .env

# Add your credentials
echo "WASSUP_GITHUB_USERNAME=your-username" >> .env
echo "WASSUP_GITHUB_ACCESS_TOKEN=your-token" >> .env
echo "WASSUP_NETLIFY_ACCESS_TOKEN=your-netlify-token" >> .env

# Load environment variables
source .env

# Or export them in your shell profile
echo 'export WASSUP_GITHUB_USERNAME="your-username"' >> ~/.bashrc
echo 'export WASSUP_GITHUB_ACCESS_TOKEN="your-token"' >> ~/.bashrc
```

### Supfile Syntax Errors

**Problem**: Ruby syntax errors in Supfile.

**Solution**:
```ruby
# Check Supfile syntax
ruby -c Supfile

# Common syntax issues:

# ❌ Missing 'do' keyword
add_pane |pane|
  pane.title = "Test"
end

# ✅ Correct syntax
add_pane do |pane|
  pane.title = "Test"
end

# ❌ Missing 'end' keyword
add_pane do |pane|
  pane.title = "Test"
  pane.content do |content|
    content.add_row("Hello")
  # Missing end here

# ✅ Correct syntax
add_pane do |pane|
  pane.title = "Test"
  pane.content do |content|
    content.add_row("Hello")
  end
end
```

### Invalid Pane Dimensions

**Problem**: Panes not displaying correctly or overlapping.

**Solution**:
```ruby
# ❌ Dimensions that don't add up to 1.0
add_pane do |pane|
  pane.height = 0.8; pane.width = 0.8; pane.top = 0; pane.left = 0
end

add_pane do |pane|
  pane.height = 0.8; pane.width = 0.8; pane.top = 0; pane.left = 0.6  # Overlaps!
end

# ✅ Correct dimensions
add_pane do |pane|
  pane.height = 0.5; pane.width = 1.0; pane.top = 0; pane.left = 0
end

add_pane do |pane|
  pane.height = 0.5; pane.width = 1.0; pane.top = 0.5; pane.left = 0
end
```

## API Integration Issues

### GitHub API Rate Limiting

**Problem**: GitHub API calls fail with rate limit errors.

**Solution**:
```ruby
# Check rate limit status
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Rate Limit"
  pane.interval = 60

  pane.content do |content|
    status = Wassup::Helpers::GitHub::RateLimiter.status
    content.add_row("Remaining: #{status[:remaining]}/#{status[:limit]}")
    content.add_row("Reset at: #{status[:reset_at]}")
  end
end

# Increase interval for rate-limited panes
add_pane do |pane|
  pane.interval = 60 * 10  # 10 minutes instead of default
  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
end
```

### Network Connectivity Issues

**Problem**: API calls fail with network timeouts.

**Solution**:
```ruby
# Add error handling to your panes
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Robust API Call"
  pane.interval = 60 * 5

  pane.content do |content|
    begin
      github = Wassup::Helpers::GitHub.new
      data = github.get("/repos/rails/rails")
      content.add_row("Repository: #{data['full_name']}")
    rescue Net::TimeoutError => e
      content.add_row("[fg=red]Timeout: #{e.message}")
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

### Authentication Failures

**Problem**: API calls fail with 401 Unauthorized errors.

**Solution**:
```bash
# Verify your tokens are valid
# For GitHub:
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/user

# For Netlify:
curl -H "Authorization: Bearer $WASSUP_NETLIFY_ACCESS_TOKEN" https://api.netlify.com/api/v1/user

# Check token permissions
# GitHub tokens need appropriate scopes:
# - repo: for private repositories
# - public_repo: for public repositories
# - user: for user information
```

## Display Issues

### Terminal Compatibility

**Problem**: Display issues in certain terminals or screen sizes.

**Solution**:
```bash
# Set terminal environment variables
export TERM=xterm-256color

# For tmux users
export TERM=screen-256color

# Check terminal capabilities
tput colors  # Should return 256 or higher

# If colors don't work, try:
export COLORTERM=truecolor
```

### Unicode Character Problems

**Problem**: Special characters or emojis display incorrectly.

**Solution**:
```bash
# Set locale for UTF-8 support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# In your Supfile, use ASCII alternatives if needed
add_pane do |pane|
  pane.content do |content|
    # Instead of emoji, use ASCII
    content.add_row("Status: OK")  # Instead of "Status: ✅"
    content.add_row("Error: Failed")  # Instead of "Error: ❌"
  end
end
```

### Layout Rendering Issues

**Problem**: Panes don't render properly or overlap.

**Solution**:
```ruby
# Debug layout by printing dimensions
add_pane do |pane|
  pane.height = 0.2; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Layout Debug"
  pane.static = true

  pane.content do |content|
    content.add_row("Terminal size: #{`tput lines`.strip}x#{`tput cols`.strip}")
    content.add_row("Pane dimensions: #{pane.height}x#{pane.width}")
    content.add_row("Pane position: #{pane.top}, #{pane.left}")
  end
end
```

## Performance Issues

### Slow Refresh Rates

**Problem**: Dashboard feels sluggish or unresponsive.

**Solution**:
```ruby
# Optimize interval settings
add_pane do |pane|
  pane.interval = 60 * 5  # 5 minutes for less critical data
  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
end

# Use caching for expensive operations
add_pane do |pane|
  pane.interval = 60
  pane.content do |content|
    # Cache expensive calculations
    @cached_data ||= expensive_calculation()
    content.add_row("Cached result: #{@cached_data}")
  end
end
```

### Memory Usage

**Problem**: Wassup consumes too much memory over time.

**Solution**:
```ruby
# Limit content size
add_pane do |pane|
  pane.content do |content|
    # Limit number of rows
    data = fetch_large_dataset()
    data.first(50).each do |item|  # Only show first 50 items
      content.add_row(item)
    end
  end
end

# Clear old data regularly
add_pane do |pane|
  pane.content do |content|
    # Clear content periodically
    content.clear if @refresh_count % 10 == 0
    @refresh_count = (@refresh_count || 0) + 1
    
    # Add new content
    content.add_row("Fresh data: #{Time.now}")
  end
end
```

## Debugging Tips

### Enable Debug Mode

```ruby
# Add debug information to your Supfile
Wassup.configure do |config|
  config.debug = true
  config.log_level = :debug
end

# Or set environment variable
export WASSUP_DEBUG=true
```

### Add Logging

```ruby
# Add logging to troubleshoot issues
add_pane do |pane|
  pane.content do |content|
    begin
      # Log API calls
      puts "Making API call at #{Time.now}"
      result = api_call()
      puts "API call succeeded: #{result.length} items"
      
      content.add_row("Success: #{result.length} items")
    rescue => e
      # Log errors
      puts "Error: #{e.message}"
      puts e.backtrace.join("\n")
      
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

### Test Individual Components

```ruby
# Create a test pane to verify specific functionality
add_pane do |pane|
  pane.title = "Component Test"
  pane.content do |content|
    content.add_row("Testing GitHub API...")
    
    begin
      github = Wassup::Helpers::GitHub.new
      user = github.get("/user")
      content.add_row("[fg=green]✓ GitHub API working")
      content.add_row("User: #{user['login']}")
    rescue => e
      content.add_row("[fg=red]✗ GitHub API failed")
      content.add_row("Error: #{e.message}")
    end
  end
end
```

## Getting Help

### Community Support

1. **GitHub Issues**: Report bugs at [wassup repository](https://github.com/your-org/wassup/issues)
2. **Documentation**: Check the [full documentation](../intro.md)
3. **Examples**: Browse [example configurations](../examples/dashboard-layouts.md)

### Diagnostic Information

When reporting issues, include:

```bash
# System information
ruby -v
gem list wassup
uname -a

# Environment variables (remove sensitive data)
env | grep WASSUP

# Terminal information
echo $TERM
tput colors

# Error logs
tail -f ~/.wassup/logs/error.log
```

### Self-Diagnosis Checklist

Before reporting issues:

- [ ] Ruby version 2.7 or higher
- [ ] All required gems installed
- [ ] Environment variables set correctly
- [ ] Supfile syntax is valid
- [ ] Network connectivity works
- [ ] API tokens have correct permissions
- [ ] Terminal supports required features

## Next Steps

- [Debug Guide](../debug/troubleshooting.md) - Advanced debugging techniques
- [Configuration Reference](../configuration/pane-properties.md) - Complete configuration options
- [API Helpers](../helpers/api-helpers.md) - Robust API integration patterns