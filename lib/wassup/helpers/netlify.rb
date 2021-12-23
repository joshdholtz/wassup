module Wassup
  module Helpers
    module Netlify
      require 'json'
      require 'rest-client'

      def self.deploys(site_id:)
        resp = RestClient::Request.execute(
          method: :get, 
          url: "https://api.netlify.com/api/v1/sites/#{site_id}/deploys", 
          headers: { "Authorization": "Bearer #{ENV['WASSUP_NETLIFY_TOKEN']}", "User-Agent": "Wassup" }
        )
        return JSON.parse(resp)
      end

    end
  end
end

module Wassup
  module Helpers
    module Netlify
      module Formatter
        def self.deploy(deploy)
          review_id = deploy["review_id"]
          context = deploy["context"]
          state = deploy["state"]
          error_message = deploy["error_message"]
          branch = deploy["branch"]
          commit_ref = deploy["commit_ref"] || "HEAD"
          url = deploy["deploy_url"]

          if error_message.to_s.downcase.include?("canceled")
            state = "cancelled"
          end

          color = "green"
          if state == "building"
            color = "yellow"
          elsif state == "cancelled"
            color = "magenta"
          elsif state == "error"
            color = "red"
          end

          display_context = context.split('-').map(&:capitalize).join(' ')
          display_context = "[fg=#{color}]#{display_context}"

          if !review_id.nil?
            display_context += " - ##{review_id}"
          end

          display_context += "[fg=gray]"
          display_context += " (#{state})"
          display_context += "[fg=white]"

          if !branch.nil? && !commit_ref.nil?
            display_context += "[fg=cyan]: #{branch}@#{commit_ref[0...7]}"
          end

          display = "#{display_context}"

          return display
        end
      end
    end
  end
end
