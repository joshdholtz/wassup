module Wassup
  module Panes
    module CircleCI
      class Workflows
        attr_accessor :vcs
        attr_accessor :org
        attr_accessor :repo

        def initialize(vcs:, org:, repo:)
          @vcs = vcs
          @org = org
          @repo = repo
        end

        def configure(pane)
          pane.content do |content|
            workflows = Helpers::CircleCI.workflows(vcs: vcs, org: org, repo: repo, limit_days: 14)
            workflows.each do |workflow|
              display = Helpers::CircleCI::Formatter.workflow(workflow)
              content.add_row(display, workflow)
            end
          end
          pane.selection('enter', 'Open workflow in browser') do |workflow|
            slug = workflow["project_slug"]
            pipeline_number = workflow["pipeline_number"]
            workflow_id = workflow["id"]
        
            url = "https://app.circleci.com/pipelines/#{slug}/#{pipeline_number}/workflows/#{workflow_id}"
            `open #{url}`
          end
        end
      end
    end
  end
end