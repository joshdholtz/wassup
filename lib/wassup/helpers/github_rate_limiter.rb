module Wassup
  module Helpers
    module GitHub
      class RateLimiter
        require 'json'
        require 'rest-client'
        require 'thread'
        require 'timeout'

        attr_reader :remaining, :reset_at, :limit, :queue_size

        def initialize
          @mutex = Mutex.new
          @queue = []
          @remaining = nil
          @reset_at = nil
          @limit = nil
          @search_remaining = nil
          @search_reset_at = nil
          @search_limit = nil
          @last_request_time = nil
          @worker_threads = []
          @running = false
          @max_queue_size = 20
          @max_concurrent_requests = 5
          @min_delay_between_requests = 1 # seconds
          @min_delay_between_search_requests = 5 # seconds (12 requests/minute to avoid abuse detection)
          @last_search_request_time = nil
          @current_requests = []
          @last_completed_request = nil
          @last_error = nil
        end

        def start_worker
          return if @running
          
          @running = true
          @max_concurrent_requests.times do |i|
            @worker_threads << Thread.new do
              process_queue
            end
          end
        end

        def stop_worker
          @running = false
          @worker_threads.each(&:join)
          @worker_threads.clear
        end

        def execute_request(method:, url:, **options)
          future = RequestFuture.new
          
          @mutex.synchronize do
            # Reject requests if queue is too large
            if @queue.size >= @max_queue_size
              future.set_error(StandardError.new("Rate limiter queue is full (#{@max_queue_size} requests). Please try again later."))
              return future.get
            end
            
            @queue << {
              future: future,
              method: method,
              url: url,
              options: options,
              queued_at: Time.now
            }
          end

          start_worker
          
          # Add timeout to prevent hanging
          begin
            Timeout.timeout(120) do
              future.get
            end
          rescue Timeout::Error
            queue_size = @mutex.synchronize { @queue.size }
            raise StandardError.new("GitHub API request timed out after 120 seconds: #{method} #{url} (queue size: #{queue_size})")
          end
        end

        def queue_size
          @mutex.synchronize { @queue.size }
        end

        def status
          @mutex.synchronize do
            next_search_available = nil
            if @last_search_request_time
              next_search_time = @last_search_request_time + @min_delay_between_search_requests
              next_search_available = [(next_search_time - Time.now).to_i, 0].max
            end
            
            {
              remaining: @remaining,
              reset_at: @reset_at,
              limit: @limit,
              search_remaining: @search_remaining,
              search_reset_at: @search_reset_at,
              search_limit: @search_limit,
              next_search_available: next_search_available,
              queue_size: @queue.size,
              running: @running,
              worker_threads: @worker_threads.size,
              current_requests: @current_requests.dup,
              last_completed: @last_completed_request,
              last_error: @last_error
            }
          end
        end

        private

        def process_queue
          while @running
            request = nil
            
            @mutex.synchronize do
              request = @queue.shift
            end

            if request
              process_request(request)
            else
              sleep(0.1)
            end
          end
        end

        def process_request(request)
          queue_time = Time.now - request[:queued_at]
          request_start = Time.now
          
          # Track current request
          @mutex.synchronize do
            @current_requests << "#{request[:method]} #{request[:url]}"
          end
          
          wait_if_needed
          
          begin
            response = make_request(
              method: request[:method],
              url: request[:url],
              **request[:options]
            )
            
            request_time = Time.now - request_start
            
            update_rate_limit_from_response(response)
            request[:future].set_result(response)
            
            # Track completed request
            @mutex.synchronize do
              @current_requests.delete("#{request[:method]} #{request[:url]}")
              @last_completed_request = "#{request[:method]} #{request[:url]} (#{request_time.round(2)}s)"
            end
            
            # Add minimum delay between requests to prevent overwhelming the API
            sleep(@min_delay_between_requests)
            
          rescue RestClient::TooManyRequests => e
            @mutex.synchronize do
              @current_requests.delete("#{request[:method]} #{request[:url]}")
              @last_error = "Rate limit exceeded: #{request[:method]} #{request[:url]}"
            end
            handle_rate_limit_exceeded(request, e)
          rescue RestClient::Forbidden => e
            @mutex.synchronize do
              @current_requests.delete("#{request[:method]} #{request[:url]}")
              @last_error = "Forbidden: #{request[:method]} #{request[:url]}"
            end
            handle_forbidden_error(request, e)
          rescue => e
            @mutex.synchronize do
              @current_requests.delete("#{request[:method]} #{request[:url]}")
              @last_error = "Error: #{e.message}"
            end
            request[:future].set_error(e)
          end
        end

        def wait_if_needed
          current_time = Time.now.to_i
          
          # Check if this is a search request and enforce minimum delay
          if @last_search_request_time
            time_since_last_search = Time.now - @last_search_request_time
            if time_since_last_search < @min_delay_between_search_requests
              sleep_time = @min_delay_between_search_requests - time_since_last_search
              sleep(sleep_time) if sleep_time > 0
            end
          end
          
          # Check search API rate limit
          if @search_remaining && @search_reset_at
            if @search_remaining == 0 && current_time < @search_reset_at
              sleep_time = @search_reset_at - current_time + 1
              sleep(sleep_time) if sleep_time > 0
              return
            end
            
            # If search API is low, add extra delay
            if @search_remaining < 5
              sleep(3)
              return
            end
          end
          
          # Check regular API rate limit
          if @remaining && @reset_at
            if @remaining == 0 && current_time < @reset_at
              sleep_time = @reset_at - current_time + 1
              sleep(sleep_time) if sleep_time > 0
              return
            end

            # Calculate dynamic delay based on remaining requests and time
            delay = calculate_dynamic_delay
            sleep(delay) if delay > 0
          end
        end

        def calculate_dynamic_delay
          return 0 unless @remaining && @reset_at

          current_time = Time.now.to_i
          time_until_reset = [@reset_at - current_time, 0].max
          
          # If we have plenty of requests remaining, no delay needed
          return 0 if @remaining > 50
          
          # If we're getting low on requests, add a small delay
          if @remaining < 10
            return 2.0
          elsif @remaining < 25
            return 1.0
          else
            return 0.5
          end
        end

        def handle_rate_limit_exceeded(request, error)
          # Check if the error response has retry-after header
          retry_after = error.response&.headers&.[](:retry_after)
          
          if retry_after
            sleep_time = retry_after.to_i + 1
          elsif @reset_at
            # Fallback to reset time or exponential backoff
            sleep_time = [@reset_at - Time.now.to_i + 1, 60].max
          else
            # Default fallback when no reset time is available
            sleep_time = 60
          end

          sleep(sleep_time)
          
          # Retry the request
          @mutex.synchronize do
            @queue.unshift(request)
          end
        end

        def handle_forbidden_error(request, error)
          # Check if this is rate limiting disguised as 403 (GitHub API inconsistency)
          response_body = error.response&.body
          if response_body&.include?("rate limit") || response_body&.include?("abuse")
            # Treat as rate limit and retry
            handle_rate_limit_exceeded(request, error)
          else
            # Genuine authentication/authorization error - don't retry
            request[:future].set_error(error)
          end
        end

        def make_request(method:, url:, **options)
          @last_request_time = Time.now
          
          # Track search requests
          if url.include?('/search/')
            @last_search_request_time = Time.now
          end

          # Set default headers for GitHub API
          headers = {
            "Accept" => "application/vnd.github.v3+json",
            "Content-Type" => "application/json"
          }.merge(options[:headers] || {})

          # Add authentication
          auth_options = {
            user: ENV["WASSUP_GITHUB_USERNAME"],
            password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
          }

          RestClient::Request.execute(
            method: method,
            url: url,
            headers: headers,
            **auth_options,
            **options.except(:headers)
          )
        end

        def update_rate_limit_from_response(response)
          # Handle case where response is a string (from tests)
          return unless response.respond_to?(:headers)
          
          headers = response.headers
          
          # Check for search API rate limit headers first
          if headers[:x_ratelimit_resource] == 'search'
            @search_remaining = headers[:x_ratelimit_remaining]&.to_i
            @search_reset_at = headers[:x_ratelimit_reset]&.to_i
            @search_limit = headers[:x_ratelimit_limit]&.to_i
          else
            # Regular API rate limit headers
            @remaining = headers[:x_ratelimit_remaining]&.to_i
            @reset_at = headers[:x_ratelimit_reset]&.to_i
            @limit = headers[:x_ratelimit_limit]&.to_i
          end
        end

        # Singleton instance
        @instance = nil
        @instance_mutex = Mutex.new

        def self.instance
          @instance_mutex.synchronize do
            @instance ||= new
          end
        end

        def self.execute_request(**args)
          instance.execute_request(**args)
        end

        def self.status
          instance.status
        end
      end

      class RequestFuture
        def initialize
          @mutex = Mutex.new
          @condition = ConditionVariable.new
          @result = nil
          @error = nil
          @completed = false
        end

        def set_result(result)
          @mutex.synchronize do
            @result = result
            @completed = true
            @condition.signal
          end
        end

        def set_error(error)
          @mutex.synchronize do
            @error = error
            @completed = true
            @condition.signal
          end
        end

        def get
          @mutex.synchronize do
            @condition.wait(@mutex) until @completed
            raise @error if @error
            @result
          end
        end
      end
    end
  end
end