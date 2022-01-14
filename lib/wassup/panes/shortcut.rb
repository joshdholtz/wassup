module Wassup
  module Panes
    module Shortcut
      class Stories
        attr_accessor :query_pages

        def initialize(query: nil, query_pages: nil)
          @query_pages = query_pages
          @query_pages ||= { "": query } if query
        end

        def configure(pane)
          pane.content do |content|
            query_pages.each do |k,v|
              stories = Helpers::Shortcut.search_stories(query: v)
              stories.each do |story|
                display = Helpers::Shortcut::Formatter.story(story)
                content.add_row(display, story, page: k.to_s)
              end
            end
          end
          pane.selection('enter', 'Open in Shortcut') do |story|
            url = story['app_url']
            `open #{url}`
          end
        end
      end
    end
  end
end