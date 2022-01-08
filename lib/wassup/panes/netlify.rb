module Wassup
  module Panes
    module Netlify
      class Deploys
        attr_accessor :site_id

        def initialize(site_id:)
          @site_id = site_id
        end

        def configure(pane)
          pane.content do |content|
            deploys = Helpers::Netlify.deploys(site_id: site_id)
            deploys.each do |deploy|
              display = Helpers::Netlify::Formatter.deploy(deploy)
              content.add_row(display, deploy)
            end
          end
          pane.selection('enter', 'Open in Netlify') do |deploy|
            url = "#{deploy['admin_url']}/deploys/#{deploy['id']}"
            `open #{url}`
          end
          pane.selection('o', 'Open preview') do |deploy|
            if deploy['state'] == 'error'
              # show alert that isn't here yet
            elsif deploy['review_id'].nil?
              `open #{deploy['url']}`
            else
              `open #{deploy['deploy_ssl_url']}`
            end
          end
        end
      end
    end
  end
end