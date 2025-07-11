module Wassup
  module Helpers
    module GitHub
      require 'json'
      require 'rest-client'
      require_relative 'github_rate_limiter'

      # https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests
      def self.issues(org:, repo:nil, q: nil)
        q_parts = []

        if repo.nil?
          q_parts << "org:#{org}"
        else
          q_parts << "repo:#{org}/#{repo}"
        end

        if q
          q_parts << q
        end

        q = q_parts.join(' ')

        items = []

        resp = RateLimiter.execute_request(
          method: :get, 
          url: "https://api.github.com/search/issues?q=#{q}"
        )
        partial_items = JSON.parse(resp)["items"]
        items += partial_items

        return items
      end

      def self.repos(org:)
        resp = RateLimiter.execute_request(
          method: :get, 
          url: "https://api.github.com/orgs/#{org}/repos"
        )
        return JSON.parse(resp)
      end

      Repo = Struct.new(:org, :repo)
      def self.pull_requests(org:, repo: nil)
        repos = []
        if repo.nil?
          repos += self.repos(org: org).map do |repo|
            Repo.new(org, repo["name"])
          end
        else
          repos << Repo.new(org, repo)
        end
        
        return repos.map do |repo|
          resp = RateLimiter.execute_request(
            method: :get, 
            url: "https://api.github.com/repos/#{repo.org}/#{repo.repo}/pulls?per_page=100"
          )

          JSON.parse(resp)
        end.flatten(1)
      end

      def self.releases(org:, repo:)
        resp = RateLimiter.execute_request(
          method: :get, 
          url: "https://api.github.com/repos/#{org}/#{repo}/releases"
        )

        return JSON.parse(resp)
      end

      # Generic GitHub API method for any endpoint
      def self.api(path:, method: :get, params: {}, body: nil)
        # Handle full URLs or relative paths
        if path.start_with?('http')
          url = path
        else
          # Ensure path starts with /
          path = "/#{path}" unless path.start_with?('/')
          url = "https://api.github.com#{path}"
        end
        
        # Add query parameters if provided
        if params.any?
          query_string = params.map { |k, v| "#{k}=#{v}" }.join('&')
          url += "?#{query_string}"
        end
        
        # Prepare request options
        options = {}
        if body
          options[:payload] = body.is_a?(String) ? body : body.to_json
        end
        
        # Make the request using the rate limiter
        resp = RateLimiter.execute_request(
          method: method,
          url: url,
          **options
        )
        
        return JSON.parse(resp)
      end
    end
  end
end

module Wassup
  module Helpers
    module GitHub
      module Formatter
        def self.issue(issue, show_repo: false, show_username: false, show_interactions: false)
          self.pr(issue, show_repo: show_repo, show_username: show_username, show_interactions: show_interactions)
        end

        def self.pr(pr, show_repo: false, show_username: false, show_interactions: false)
          number = pr["number"]
          title = pr["title"]
          created_at = pr["created_at"]

          repo_name = ""
          if show_repo
            repo_url_parts = pr["repository_url"].split("/")
            repo_name = "[fg=gray]#{repo_url_parts.last} "
          end

          username = ""
          if show_username
            username = "[fg=magenta]#{pr["user"]["login"]} "
          end

          interactions = ""
          if show_interactions
            interaction_count = pr["comments"] + pr["reactions"]["total_count"]
            interactions = "[fg=red]#{interaction_count} "
          end

          number_formatted = '%-7.7s' % "##{number}"

          date = Time.parse(created_at)
          days = (Time.now - date).to_i / (24 * 60 * 60)
          days_formatted = '%3.3s' % days.to_s

          display = "[fg=yellow]#{number_formatted}[fg=cyan] #{days_formatted}d ago #{interactions}#{repo_name}#{username}[fg=white]#{title}"

          return display
        end

        def self.release(release)
          tag_name = release["tag_name"]
          name = release["name"]
          published_at = release["published_at"]

          date = Time.parse(published_at)
          days = (Time.now - date).to_i / (24 * 60 * 60)
          days_formatted = '%3.3s' % days.to_s

          display = "[fg=yellow]#{tag_name} [fg=cyan]#{days_formatted}d ago [fg=gray]#{name}"

          return display 
        end
      end
    end
  end
end
