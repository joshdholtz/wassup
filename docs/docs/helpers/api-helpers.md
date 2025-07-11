---
sidebar_position: 1
---

# API Helpers

Common API helpers and utilities for integrating with external services and APIs.

## Overview

API helpers provide standardized methods for:
- Making HTTP requests with proper error handling
- Managing authentication and rate limiting
- Processing and formatting API responses
- Caching API data for performance

## HTTP Request Helper

### Basic Usage

```ruby title="Supfile"
require 'net/http'
require 'json'

class APIHelper
  def self.get(url, headers = {})
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    
    response = http.request(request)
    
    case response.code
    when '200'
      JSON.parse(response.body)
    else
      raise "HTTP Error: #{response.code} - #{response.message}"
    end
  end
  
  def self.post(url, data, headers = {})
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    headers.each { |key, value| request[key] = value }
    request.body = data.to_json
    
    response = http.request(request)
    
    case response.code
    when '200', '201'
      JSON.parse(response.body)
    else
      raise "HTTP Error: #{response.code} - #{response.message}"
    end
  end
end
```

### Error Handling

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "API Status Check"
  pane.interval = 60 * 5

  pane.content do |content|
    begin
      # Example API call with error handling
      response = APIHelper.get('https://api.github.com/zen')
      content.add_row("GitHub API Status: [fg=green]✓ Online")
      content.add_row("Message: #{response}")
    rescue => e
      content.add_row("GitHub API Status: [fg=red]✗ Error")
      content.add_row("Error: #{e.message}")
    end
  end
end
```

## Authentication Helper

### Token-Based Authentication

```ruby title="Supfile"
class AuthHelper
  def self.bearer_token(token)
    { 'Authorization' => "Bearer #{token}" }
  end
  
  def self.api_key(key, header_name = 'X-API-Key')
    { header_name => key }
  end
  
  def self.basic_auth(username, password)
    encoded = Base64.strict_encode64("#{username}:#{password}")
    { 'Authorization' => "Basic #{encoded}" }
  end
end

# Usage example
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Authenticated API Call"
  pane.interval = 60 * 5

  pane.content do |content|
    token = ENV['API_TOKEN']
    headers = AuthHelper.bearer_token(token)
    
    begin
      response = APIHelper.get('https://api.example.com/data', headers)
      content.add_row("Data retrieved successfully")
      content.add_row("Count: #{response['count']}")
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## Rate Limiting Helper

### Request Throttling

```ruby title="Supfile"
class RateLimitHelper
  @last_request_time = {}
  @request_counts = {}
  
  def self.throttle(key, min_interval = 1.0)
    now = Time.now
    
    if @last_request_time[key]
      elapsed = now - @last_request_time[key]
      if elapsed < min_interval
        sleep(min_interval - elapsed)
      end
    end
    
    @last_request_time[key] = Time.now
  end
  
  def self.rate_limit(key, max_requests = 60, time_window = 60)
    now = Time.now.to_i
    window_start = now - time_window
    
    @request_counts[key] ||= []
    @request_counts[key].reject! { |timestamp| timestamp < window_start }
    
    if @request_counts[key].length >= max_requests
      sleep_time = @request_counts[key].first - window_start + 1
      sleep(sleep_time) if sleep_time > 0
      @request_counts[key].shift
    end
    
    @request_counts[key] << now
  end
end
```

## Caching Helper

### Simple API Response Caching

```ruby title="Supfile"
class CacheHelper
  @cache = {}
  @cache_timestamps = {}
  
  def self.cached_request(key, ttl = 300, &block)
    now = Time.now.to_i
    
    if @cache[key] && @cache_timestamps[key] && (now - @cache_timestamps[key]) < ttl
      return @cache[key]
    end
    
    result = block.call
    @cache[key] = result
    @cache_timestamps[key] = now
    result
  end
  
  def self.clear_cache(key = nil)
    if key
      @cache.delete(key)
      @cache_timestamps.delete(key)
    else
      @cache.clear
      @cache_timestamps.clear
    end
  end
end

# Usage example
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Cached API Data"
  pane.interval = 60

  pane.content do |content|
    data = CacheHelper.cached_request('api_status', 300) do
      APIHelper.get('https://api.example.com/status')
    end
    
    content.add_row("Cached API Status: #{data['status']}")
    content.add_row("Last updated: #{data['timestamp']}")
  end
end
```

## Data Processing Helper

### JSON Response Processing

```ruby title="Supfile"
class DataHelper
  def self.extract_fields(data, fields)
    if data.is_a?(Array)
      data.map { |item| extract_fields(item, fields) }
    else
      result = {}
      fields.each do |field|
        if field.include?('.')
          result[field] = dig_value(data, field.split('.'))
        else
          result[field] = data[field]
        end
      end
      result
    end
  end
  
  def self.dig_value(data, path)
    path.reduce(data) { |current, key| current&.dig(key) }
  end
  
  def self.filter_by(data, field, value)
    return [] unless data.is_a?(Array)
    data.select { |item| item[field] == value }
  end
  
  def self.sort_by_field(data, field, ascending = true)
    return [] unless data.is_a?(Array)
    sorted = data.sort_by { |item| item[field] || '' }
    ascending ? sorted : sorted.reverse
  end
end

# Usage example
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Processed API Data"
  pane.interval = 60 * 5

  pane.content do |content|
    begin
      raw_data = APIHelper.get('https://api.example.com/items')
      
      # Extract only needed fields
      processed_data = DataHelper.extract_fields(raw_data, ['name', 'status', 'created_at'])
      
      # Filter active items
      active_items = DataHelper.filter_by(processed_data, 'status', 'active')
      
      # Sort by creation date
      sorted_items = DataHelper.sort_by_field(active_items, 'created_at', false)
      
      content.add_row("Active Items (#{sorted_items.length})")
      sorted_items.each do |item|
        content.add_row("#{item['name']} - #{item['created_at']}")
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## Webhook Helper

### Simple Webhook Server

```ruby title="Supfile"
require 'webrick'

class WebhookHelper
  def self.start_server(port = 8080, &block)
    server = WEBrick::HTTPServer.new(Port: port, Logger: WEBrick::Log.new('/dev/null'))
    
    server.mount_proc '/webhook' do |req, res|
      case req.request_method
      when 'POST'
        begin
          data = JSON.parse(req.body)
          result = block.call(data)
          res.status = 200
          res.body = result.to_json
        rescue => e
          res.status = 500
          res.body = { error: e.message }.to_json
        end
      else
        res.status = 405
        res.body = { error: 'Method not allowed' }.to_json
      end
    end
    
    trap('INT') { server.shutdown }
    server.start
  end
end

# Usage (in separate process)
# WebhookHelper.start_server(8080) do |data|
#   puts "Received webhook: #{data}"
#   { status: 'received' }
# end
```

## Configuration Helper

### Environment Configuration

```ruby title="Supfile"
class ConfigHelper
  def self.required_env(key)
    value = ENV[key]
    raise "Missing required environment variable: #{key}" unless value
    value
  end
  
  def self.optional_env(key, default = nil)
    ENV[key] || default
  end
  
  def self.env_to_bool(key, default = false)
    value = ENV[key]
    return default unless value
    %w[true yes 1 on].include?(value.downcase)
  end
  
  def self.env_to_int(key, default = 0)
    value = ENV[key]
    return default unless value
    value.to_i
  end
end

# Usage example
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Configuration Check"
  pane.interval = 60 * 30

  pane.content do |content|
    begin
      api_url = ConfigHelper.required_env('API_URL')
      api_key = ConfigHelper.required_env('API_KEY')
      timeout = ConfigHelper.env_to_int('API_TIMEOUT', 30)
      debug = ConfigHelper.env_to_bool('DEBUG', false)
      
      content.add_row("API URL: #{api_url}")
      content.add_row("API Key: #{api_key[0..8]}...")
      content.add_row("Timeout: #{timeout}s")
      content.add_row("Debug: #{debug}")
      
    rescue => e
      content.add_row("[fg=red]Configuration Error: #{e.message}")
    end
  end
end
```

## Error Handling Patterns

### Retry Logic

```ruby title="Supfile"
class RetryHelper
  def self.with_retry(max_retries = 3, delay = 1, &block)
    retries = 0
    
    begin
      block.call
    rescue => e
      retries += 1
      if retries <= max_retries
        sleep(delay * retries)
        retry
      else
        raise e
      end
    end
  end
end

# Usage example
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Reliable API Call"
  pane.interval = 60 * 5

  pane.content do |content|
    begin
      data = RetryHelper.with_retry(3, 2) do
        APIHelper.get('https://api.example.com/unreliable-endpoint')
      end
      
      content.add_row("API call succeeded")
      content.add_row("Data: #{data}")
      
    rescue => e
      content.add_row("[fg=red]API call failed after retries: #{e.message}")
    end
  end
end
```

## Best Practices

1. **Always handle errors gracefully** - Use try/catch blocks and provide meaningful error messages
2. **Respect rate limits** - Implement throttling and queuing for API calls
3. **Cache when appropriate** - Reduce API calls by caching frequently accessed data
4. **Use environment variables** - Store sensitive data like API keys in environment variables
5. **Log important events** - Add logging for debugging and monitoring
6. **Validate input data** - Check API responses for expected structure and data types

## Next Steps

- [GitHub Integration](../integrations/github.md) - GitHub-specific API helpers
- [Troubleshooting](../troubleshooting/common-issues.md) - Common API integration issues
- [Configuration Guide](../configuration/understanding-supfile.md) - Supfile configuration patterns