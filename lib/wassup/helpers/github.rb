module Wassup
  module Helpers
    module GitHub
      require 'json'
      require 'rest-client'

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

        resp = RestClient::Request.execute(
          method: :get, 
          url: "https://api.github.com/search/issues?q=#{q}", 
          user: ENV["WASSUP_GITHUB_USERNAME"],
          password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"],
          headers: { "Accept": "application/vnd.github.v3+json", "Content-Type": "application/json" },
        )
        partial_items = JSON.parse(resp)["items"]
        items += partial_items

        return items
      end

      def self.repos(org:)
        resp = RestClient::Request.execute(
          method: :get, 
          url: "https://api.github.com/orgs/#{org}/repos", 
          user: ENV["WASSUP_GITHUB_USERNAME"],
          password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
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
          resp = RestClient::Request.execute(
            method: :get, 
            url: "https://api.github.com/repos/#{repo.org}/#{repo.repo}/pulls?per_page=100", 
            user: ENV["WASSUP_GITHUB_USERNAME"],
            password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
          )

          JSON.parse(resp)
        end.flatten(1)
      end

      def self.releases(org:, repo:)
        resp = RestClient::Request.execute(
          method: :get, 
          url: "https://api.github.com/repos/#{org}/#{repo}/releases", 
          user: ENV["WASSUP_GITHUB_USERNAME"],
          password: ENV["WASSUP_GITHUB_ACCESS_TOKEN"]
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
        def self.issue(issue, show_repo: false, show_interactions: false)
          self.pr(issue, show_repo: show_repo, show_interactions: show_interactions)
        end

        def self.pr(pr, show_repo: false, show_interactions: false)
          number = pr["number"]
          title = pr["title"]
          created_at = pr["created_at"]

          repo_name = ""
          if show_repo
            repo_url_parts = pr["repository_url"].split("/")
            repo_name = "[fg=gray]#{repo_url_parts.last} "
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

          display = "[fg=yellow]#{number_formatted}[fg=cyan] #{days_formatted}d ago #{interactions}#{repo_name}[fg=white]#{title}"

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
