#!/usr/bin/env ruby
# Demo script to show how the rate limiter handles burst requests

require_relative '../lib/wassup/helpers/github_rate_limiter'

# Mock the RestClient for demo purposes
class MockRestClient
  def self.execute(**args)
    # Simulate API response time
    sleep(0.05)
    
    # Create a mock response with rate limit headers
    response = OpenStruct.new(
      body: '{"items": []}',
      headers: {
        x_ratelimit_remaining: rand(100..4999),
        x_ratelimit_reset: (Time.now + 3600).to_i,
        x_ratelimit_limit: 5000
      }
    )
    
    puts "Request processed: #{args[:url]} (remaining: #{response.headers[:x_ratelimit_remaining]})"
    response.body
  end
end

# Replace RestClient with our mock
module RestClient
  Request = MockRestClient
end

# Test burst handling
puts "Testing Rate Limiter with Burst Requests"
puts "=" * 50

rate_limiter = Wassup::Helpers::GitHub::RateLimiter.instance

# Send 20 requests simultaneously
puts "\nSending 20 requests simultaneously..."
start_time = Time.now

threads = []
20.times do |i|
  threads << Thread.new do
    begin
      rate_limiter.execute_request(
        method: :get,
        url: "https://api.github.com/test/#{i}"
      )
      puts "Request #{i+1} completed"
    rescue => e
      puts "Request #{i+1} failed: #{e.message}"
    end
  end
end

# Wait for all requests to complete
threads.each(&:join)

end_time = Time.now
puts "\nAll requests completed in #{(end_time - start_time).round(2)} seconds"

# Show final status
puts "\nFinal Rate Limiter Status:"
puts rate_limiter.status

# Cleanup
rate_limiter.stop_worker