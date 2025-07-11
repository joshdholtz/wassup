---
sidebar_position: 1
---

# API Helpers & Utilities

Wassup provides powerful helper utilities for working with APIs, data formatting, and custom integrations.

## GitHub Helper

The GitHub helper provides authenticated API access with built-in rate limiting.

### Basic Usage

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Custom GitHub Integration"
  pane.interval = 60 * 5

  pane.content do |content|
    # Use the GitHub helper directly
    github = Wassup::Helpers::GitHub.new
    
    # Get repository information
    repo_data = github.get("/repos/rails/rails")
    content.add_row("Repository: #{repo_data['full_name']}")
    content.add_row("Stars: #{repo_data['stargazers_count']}")
    content.add_row("Forks: #{repo_data['forks_count']}")
    content.add_row("Open issues: #{repo_data['open_issues_count']}")
  end
end
```

### Advanced GitHub API Usage

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Repository Analytics"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    begin
      # Get repository statistics
      repo = github.get("/repos/#{ENV['GITHUB_ORG']}/#{ENV['GITHUB_REPO']}")
      
      # Get recent commits
      commits = github.get("/repos/#{ENV['GITHUB_ORG']}/#{ENV['GITHUB_REPO']}/commits", {
        per_page: 5,
        since: (Time.now - 24*60*60).iso8601  # Last 24 hours
      })
      
      # Get contributors
      contributors = github.get("/repos/#{ENV['GITHUB_ORG']}/#{ENV['GITHUB_REPO']}/contributors", {
        per_page: 10
      })
      
      # Display repository info
      content.add_row("=== Repository Info ===")
      content.add_row("Name: #{repo['full_name']}")
      content.add_row("Description: #{repo['description']}")
      content.add_row("Language: #{repo['language']}")
      content.add_row("Stars: #{repo['stargazers_count']}")
      content.add_row("Forks: #{repo['forks_count']}")
      content.add_row("")
      
      # Display recent commits
      content.add_row("=== Recent Commits ===")
      commits.each do |commit|
        author = commit['commit']['author']['name']
        message = commit['commit']['message'].split("\n").first
        content.add_row("#{author}: #{message}", commit)
      end
      
      content.add_row("")
      
      # Display top contributors
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
  pane.title = "GitHub Search Results"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    github = Wassup::Helpers::GitHub.new
    
    # Search for repositories
    search_results = github.search("ruby dashboard terminal", type: 'repositories')
    
    content.add_row("=== Repository Search Results ===")
    search_results['items'].each do |repo|
      content.add_row("#{repo['full_name']} (⭐ #{repo['stargazers_count']})", repo)
    end
    
    content.add_row("")
    
    # Search for issues
    issue_results = github.search("is:issue is:open label:bug", type: 'issues')
    
    content.add_row("=== Issue Search Results ===")
    issue_results['items'].each do |issue|
      content.add_row("##{issue['number']} #{issue['title']}", issue)
    end
  end

  pane.selection do |data|
    `open #{data['html_url']}`
  end
end
```

## Rate Limiter

Monitor and control API rate limits across your dashboard.

### Rate Limit Monitoring

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "API Rate Limits"
  pane.interval = 60

  pane.content do |content|
    # GitHub rate limit status
    github_status = Wassup::Helpers::GitHub::RateLimiter.status
    
    content.add_row("=== GitHub API Rate Limits ===")
    content.add_row("Core API: #{github_status[:remaining]}/#{github_status[:limit]}")
    content.add_row("Reset at: #{github_status[:reset_at]}")
    content.add_row("Search API: #{github_status[:search_remaining]}/#{github_status[:search_limit]}")
    content.add_row("Search reset: #{github_status[:search_reset_at]}")
    content.add_row("Queue size: #{github_status[:queue_size]}")
    content.add_row("Worker running: #{github_status[:running] ? 'Yes' : 'No'}")
    
    # Color coding based on remaining requests
    remaining_pct = (github_status[:remaining].to_f / github_status[:limit].to_f) * 100
    
    if remaining_pct < 10
      content.add_row("[fg=red]⚠ Low rate limit remaining")
    elsif remaining_pct < 25
      content.add_row("[fg=yellow]⚠ Rate limit getting low")
    else
      content.add_row("[fg=green]✓ Rate limit OK")
    end
  end
end
```

### Custom Rate Limiting

```ruby title="Supfile"
# Custom rate limiter for your own APIs
class CustomRateLimiter
  def initialize(max_requests, time_window)
    @max_requests = max_requests
    @time_window = time_window
    @requests = []
  end
  
  def can_make_request?
    now = Time.now
    # Remove old requests outside the time window
    @requests.reject! { |time| now - time > @time_window }
    
    @requests.length < @max_requests
  end
  
  def make_request
    if can_make_request?
      @requests << Time.now
      yield
    else
      raise "Rate limit exceeded"
    end
  end
  
  def remaining
    @max_requests - @requests.length
  end
end

# Usage in a pane
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Custom API with Rate Limiting"
  pane.interval = 60

  pane.content do |content|
    # Create rate limiter: 10 requests per 60 seconds
    @rate_limiter ||= CustomRateLimiter.new(10, 60)
    
    begin
      @rate_limiter.make_request do
        # Your API call here
        response = `curl -s https://api.example.com/data`
        data = JSON.parse(response)
        
        data.each do |item|
          content.add_row(item['name'], item)
        end
      end
      
      content.add_row("")
      content.add_row("Rate limit remaining: #{@rate_limiter.remaining}")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## HTTP Utilities

### Simple HTTP Client

```ruby title="Supfile"
require 'net/http'
require 'json'

class SimpleHttpClient
  def self.get(url, headers = {})
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      raise "HTTP #{response.code}: #{response.message}"
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Custom HTTP Client"
  pane.interval = 60

  pane.content do |content|
    begin
      # Make API request
      data = SimpleHttpClient.get('https://api.github.com/zen')
      content.add_row("GitHub Zen: #{data}")
      
      # Request with headers
      user_data = SimpleHttpClient.get(
        'https://api.github.com/user',
        'Authorization' => "token #{ENV['WASSUP_GITHUB_ACCESS_TOKEN']}"
      )
      content.add_row("User: #{user_data['login']}")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

### HTTP Health Checker

```ruby title="Supfile"
class HealthChecker
  def self.check_endpoint(url, timeout = 5)
    start_time = Time.now
    
    begin
      response = `curl -s -o /dev/null -w "%{http_code}:%{time_total}" --max-time #{timeout} #{url}`
      code, time = response.split(':')
      
      {
        url: url,
        status: code.to_i,
        response_time: time.to_f,
        healthy: code.to_i == 200,
        duration: Time.now - start_time
      }
    rescue => e
      {
        url: url,
        status: 0,
        response_time: 0,
        healthy: false,
        error: e.message,
        duration: Time.now - start_time
      }
    end
  end
  
  def self.check_multiple(urls, timeout = 5)
    urls.map { |url| check_endpoint(url, timeout) }
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Service Health Check"
  pane.interval = 60

  pane.content do |content|
    endpoints = [
      'https://api.github.com/zen',
      'https://httpbin.org/status/200',
      'https://httpbin.org/delay/2',
      'https://httpbin.org/status/500'
    ]
    
    results = HealthChecker.check_multiple(endpoints)
    
    results.each do |result|
      if result[:healthy]
        content.add_row("[fg=green]✓ #{result[:url]} (#{result[:response_time]}s)")
      else
        content.add_row("[fg=red]✗ #{result[:url]} (#{result[:status]})")
      end
    end
    
    # Summary
    healthy_count = results.count { |r| r[:healthy] }
    total_count = results.length
    
    content.add_row("")
    if healthy_count == total_count
      content.add_row("[fg=green]All services healthy (#{healthy_count}/#{total_count})")
    else
      content.add_row("[fg=red]#{total_count - healthy_count} service(s) down")
    end
  end
end
```

## Data Processing Utilities

### JSON Processor

```ruby title="Supfile"
class JsonProcessor
  def self.extract_paths(data, paths)
    result = {}
    paths.each do |key, path|
      result[key] = extract_path(data, path)
    end
    result
  end
  
  def self.extract_path(data, path)
    path.split('.').reduce(data) do |current, key|
      if current.is_a?(Array)
        current.map { |item| item[key] }
      else
        current[key]
      end
    end
  rescue
    nil
  end
  
  def self.flatten_array(arr)
    arr.flatten.compact
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "JSON Data Processing"
  pane.interval = 60

  pane.content do |content|
    begin
      # Fetch complex JSON data
      response = `curl -s https://api.github.com/repos/rails/rails/pulls?state=open&per_page=5`
      data = JSON.parse(response)
      
      # Extract specific fields
      extracted = JsonProcessor.extract_paths(data, {
        'titles' => 'title',
        'authors' => 'user.login',
        'numbers' => 'number'
      })
      
      # Display processed data
      content.add_row("=== PR Titles ===")
      extracted['titles'].each { |title| content.add_row(title) }
      
      content.add_row("")
      content.add_row("=== Authors ===")
      extracted['authors'].uniq.each { |author| content.add_row(author) }
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

### Data Formatter

```ruby title="Supfile"
class DataFormatter
  def self.format_bytes(bytes)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    return '0 B' if bytes == 0
    
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min
    
    "%.1f %s" % [bytes.to_f / (1024 ** exp), units[exp]]
  end
  
  def self.format_duration(seconds)
    return "#{seconds}s" if seconds < 60
    return "#{seconds / 60}m #{seconds % 60}s" if seconds < 3600
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m"
  end
  
  def self.format_number(num)
    case num
    when 0..999
      num.to_s
    when 1000..999_999
      "#{(num / 1000.0).round(1)}K"
    when 1_000_000..999_999_999
      "#{(num / 1_000_000.0).round(1)}M"
    else
      "#{(num / 1_000_000_000.0).round(1)}B"
    end
  end
  
  def self.format_percentage(value, total)
    return "0%" if total == 0
    "#{((value.to_f / total.to_f) * 100).round(1)}%"
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Data Formatting Examples"
  pane.interval = 60

  pane.content do |content|
    # File sizes
    content.add_row("=== File Sizes ===")
    [1024, 1048576, 1073741824].each do |size|
      content.add_row("#{size} bytes = #{DataFormatter.format_bytes(size)}")
    end
    
    # Durations
    content.add_row("")
    content.add_row("=== Durations ===")
    [30, 150, 3661].each do |duration|
      content.add_row("#{duration}s = #{DataFormatter.format_duration(duration)}")
    end
    
    # Numbers
    content.add_row("")
    content.add_row("=== Numbers ===")
    [1500, 1500000, 1500000000].each do |num|
      content.add_row("#{num} = #{DataFormatter.format_number(num)}")
    end
    
    # Percentages
    content.add_row("")
    content.add_row("=== Percentages ===")
    [[25, 100], [750, 1000], [33, 99]].each do |value, total|
      content.add_row("#{value}/#{total} = #{DataFormatter.format_percentage(value, total)}")
    end
  end
end
```

## Caching Utilities

### Simple Cache

```ruby title="Supfile"
class SimpleCache
  def initialize(ttl = 300)
    @cache = {}
    @ttl = ttl
  end
  
  def get(key)
    entry = @cache[key]
    return nil unless entry
    
    if Time.now - entry[:timestamp] > @ttl
      @cache.delete(key)
      return nil
    end
    
    entry[:value]
  end
  
  def set(key, value)
    @cache[key] = {
      value: value,
      timestamp: Time.now
    }
  end
  
  def fetch(key, &block)
    value = get(key)
    return value if value
    
    value = block.call
    set(key, value)
    value
  end
  
  def clear
    @cache.clear
  end
  
  def size
    @cache.size
  end
end

# Global cache instance
$cache = SimpleCache.new(300)  # 5 minute TTL

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Cached API Data"
  pane.interval = 60

  pane.content do |content|
    begin
      # Fetch data with caching
      data = $cache.fetch('github_zen') do
        # This will only run if not cached
        `curl -s https://api.github.com/zen`
      end
      
      content.add_row("Cached data: #{data}")
      content.add_row("Cache size: #{$cache.size} items")
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## Configuration Helpers

### Environment Configuration

```ruby title="Supfile"
class ConfigHelper
  def self.get_env(key, default = nil)
    ENV[key] || default
  end
  
  def self.required_env(key)
    value = ENV[key]
    raise "Required environment variable #{key} not set" unless value
    value
  end
  
  def self.boolean_env(key, default = false)
    value = ENV[key]
    return default if value.nil?
    
    %w[true 1 yes on].include?(value.downcase)
  end
  
  def self.integer_env(key, default = 0)
    value = ENV[key]
    return default if value.nil?
    
    value.to_i
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Configuration"
  pane.interval = 60

  pane.content do |content|
    content.add_row("=== Environment Configuration ===")
    content.add_row("GitHub Org: #{ConfigHelper.get_env('GITHUB_ORG', 'default-org')}")
    content.add_row("Debug Mode: #{ConfigHelper.boolean_env('DEBUG', false)}")
    content.add_row("Refresh Rate: #{ConfigHelper.integer_env('REFRESH_RATE', 60)}s")
    
    begin
      token = ConfigHelper.required_env('WASSUP_GITHUB_ACCESS_TOKEN')
      content.add_row("GitHub Token: [CONFIGURED]")
    rescue => e
      content.add_row("[fg=red]GitHub Token: #{e.message}")
    end
  end
end
```

## Next Steps

- [Formatters & Styling](../helpers/formatters.md) - Text formatting and styling utilities
- [Advanced Configuration](../advanced/complex-layouts.md) - Complex layouts and features
- [Debug Mode](../debug/troubleshooting.md) - Testing and troubleshooting