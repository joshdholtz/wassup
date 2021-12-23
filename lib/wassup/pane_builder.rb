
module Wassup
  class PaneBuilder
    attr_accessor :height
    attr_accessor :width
    attr_accessor :top
    attr_accessor :left

    attr_accessor :highlight

    attr_accessor :title
    attr_accessor :description

    attr_accessor :show_refresh

    attr_accessor :interval
    attr_accessor :content_block
    attr_accessor :selection_blocks
    attr_accessor :selection_blocks_description

    class ContentBuilder
      attr_accessor :contents

      def initialize(contents)
        @contents = contents
        @need_to_clear = true
        @show_refresh = true
      end

      def clear=(clear)
        @need_to_clear = clear
      end

      def add_row(display, object=nil, page:nil)
        if @need_to_clear
          @need_to_clear = false
          self.contents = []
        end

        content = nil

        # Create contents if none
        if page.nil?
          if self.contents.empty?
            content = Pane::Content.new
            self.contents << content
          else
            content = self.contents.first
          end
        elsif page.is_a?(String)
          content = self.contents.find do |content|
            content.title == page
          end

          if content.nil?
            content = Pane::Content.new(page)
            self.contents << content
          end
        end

        content.add_row(display, object)
      end
    end

    def initialize()
      @height = 1
      @weight = 1
      @top = 0
      @left = 0

      @highlight = false
      @interval = 60 * 5 

      @selection_blocks = {}
      @selection_blocks_description = {}
    end

    def content(&block)
      self.content_block = block
    end
    def selection(input=10, description=nil, &block)
      if input.to_s.downcase == "enter"
        input = 10
      end

      description_input = input
      if input.to_s == "10"
        description_input = "enter"
      end

      self.selection_blocks[input] = block
      self.selection_blocks_description[description_input] = description
    end
  end
end
