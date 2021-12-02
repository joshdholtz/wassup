
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
    attr_accessor :selection_block

    def content(&block)
      self.content_block = block
    end
    def selection(&block)
      self.selection_block = block
    end
  end
end
