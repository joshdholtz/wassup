module Wassup
  module Helpers
    module GitHub
      require 'json'
      require 'rest-client'

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
    end
  end
end

module Wassup
  module Helpers
    module GitHub
      module Formatter
        def self.pr(pr)
          number = pr["number"]
          title = pr["title"]
          created_at = pr["created_at"]

          date = Time.parse(created_at)
          days = (Time.now - date).to_i / (24 * 60 * 60)
          days_formatted = '%3.3s' % days.to_s

          display = "[fg=yellow]##{number}[fg=cyan] #{days_formatted}d ago[fg=white] #{title}"

          return display
        end
      end
    end
  end
end
