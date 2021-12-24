module Wassup
  module Helpers
    module Shortcut
      require 'json'
      require 'rest-client'

      def self.members
        endpoint = "https://api.app.shortcut.com"
        resp = RestClient::Request.execute(
          method: :get, 
          url: "#{endpoint}/api/v3/members",
          headers: { "Shortcut-Token": ENV['WASSUP_SHORTCUT_TOKEN'], "Content-Type": "application/json" }
        )
        return JSON.parse(resp)
      end

      def self.workflows
        endpoint = "https://api.app.shortcut.com"
        resp = RestClient::Request.execute(
          method: :get, 
          url: "#{endpoint}/api/v3/workflows",
          headers: { "Shortcut-Token": ENV['WASSUP_SHORTCUT_TOKEN'], "Content-Type": "application/json" }
        )
        return JSON.parse(resp)
      end

      def self.search_stories(query:, page_size: 25)
        endpoint = "https://api.app.shortcut.com"

        members = self.members
        workflows = self.workflows

        stories = []

        resp = RestClient::Request.execute(
          method: :get, 
          url: "#{endpoint}/api/v3/search/stories",
          payload: { page_size: page_size, query: query },
          headers: { "Shortcut-Token": ENV['WASSUP_SHORTCUT_TOKEN'], "Content-Type": "application/json" }
        )
        json = JSON.parse(resp)
        stories += json["data"]

        next_url = json["next"]
        while !next_url.nil?
          resp = RestClient::Request.execute(
            method: :get, 
            url: "#{endpoint}#{next_url}",
            headers: { "Shortcut-Token": ENV['WASSUP_SHORTCUT_TOKEN'], "Content-Type": "application/json" }
          )
          json = JSON.parse(resp)
          stories += json["data"]
          next_url = json["next"]
        end

        stories = stories.map do |story|
          story["followers"] = story["follower_ids"].map do |owner_id|
            members.find do |member|
              member["id"] == owner_id
            end 
          end

          story["owners"] = story["owner_ids"].map do |owner_id|
            members.find do |member|
              member["id"] == owner_id
            end 
          end

          if (workflow_id = story["workflow_id"]) && (workflow_state_id = story["workflow_state_id"])
            workflow = workflows.find do |workflow|
              workflow["id"] == workflow_id
            end

            story["workflow"] = workflow
            if workflow
              story["workflow_state"] = workflow["states"].find do |workflow_state|
                workflow_state["id"] == workflow_state_id
              end
            end
          end

          story
        end

        return stories
      end

    end
  end
end

module Wassup
  module Helpers
    module Shortcut
      module Formatter
        def self.story(story)
          id = story["id"]
          name = story["name"]
          state = story["workflow_state"]["name"]

          mention_name = (story["owners"] || {}).map do |member|
            member["profile"]["mention_name"]
          end.join(", ")

          id_formatted = '%-7.7s' % "##{id}"

          display = "[fg=yellow]#{id_formatted} [fg=cyan]#{state} [fg=white]#{mention_name} [fg=gray]#{name}"

          return display
        end
      end
    end
  end
end
