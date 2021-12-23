module Wassup
  module Helpers
    module CircleCI
      def self.workflows(vcs:, org:, repo:, limit_days: nil)
        require 'json'
        require 'rest-client'

        resp = RestClient::Request.execute(
          method: :get, 
          url: "https://circleci.com/api/v2/project/#{vcs}/#{org}/#{repo}/pipeline", 
          headers: { "Circle-Token": ENV["WASSUP_CIRCLE_CI_API_TOKEN"] }
        )
        json = JSON.parse(resp)

        return json["items"].select do |item|
          if !limit_days.nil?
            date = Time.parse(item["updated_at"])
            days = (Time.now - date).to_i / (24 * 60 * 60)
            days < limit_days
          else
            true
          end
        end.map do |pipeline|
          id = pipeline["id"]

          resp = RestClient::Request.execute(
            method: :get, 
            url: "https://circleci.com/api/v2/pipeline/#{id}/workflow", 
            headers: { "Circle-Token": ENV["WASSUP_CIRCLE_CI_API_TOKEN"] }
          )
          json = JSON.parse(resp)
          workflow = json["items"].first

          if workflow
            workflow["pipeline"] = pipeline
          end

          workflow
        end.compact
      end
    end
  end
end

module Wassup
  module Helpers
    module CircleCI
      module Formatter
        def self.workflow(workflow)
          pipeline = workflow["pipeline"]
          number = pipeline["number"]
          message = (pipeline["vcs"]["commit"] || {})["subject"]
          login = pipeline["trigger"]["actor"]["login"]

          status = workflow["status"]

          if status == "failed"
            status = "[fg=red]#{status}[fg=white]"
          elsif status == "success"
            status = "[fg=green]#{status}[fg=white]"
          else
            status = "[fg=yellow]#{status}[fg=white]"
          end

          display = "#{number} (#{status}) by #{login} - #{message}"
          
          return display
        end
      end
    end
  end
end
