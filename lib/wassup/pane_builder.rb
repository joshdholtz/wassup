
module Wassup
  class PaneBuilder
    attr_accessor :height
    attr_accessor :width
    attr_accessor :top
    attr_accessor :left

    attr_accessor :highlight

    attr_accessor :title

    attr_accessor :interval
    attr_accessor :content_block
    attr_accessor :selection_blocks

    class ContentBuilder
      attr_accessor :clear
      attr_accessor :content

      def initialize()
        @clear = false
        @content = []
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
    end

    def content(&block)
      self.content_block = block
    end
    def selection(input=10, &block)
      self.selection_blocks[input] = block
    end
  end
end
