require 'curses'

module Wassup
  class Color
    attr_accessor :color_pair

    module Pair
      BLACK = 0
      BLUE = 1
      CYAN = 2
      GREEN = 3
      MAGENTA = 4
      RED = 5
      WHITE = 15
      YELLOW = 7

      NORMAL = 20
      HIGHLIGHT = 21

      GRAY = 22

      BORDER = 20
      BORDER_FOCUS = 7

      TITLE = 20
      TITLE_FOCUS = 20
    end

    def self.init
      Curses.use_default_colors()

      Curses.init_pair(Pair::NORMAL, Pair::WHITE, 0) #white foreground, black background
      Curses.init_pair(Pair::HIGHLIGHT, 0, Pair::WHITE) # black foreground, white background

#      Curses.init_pair(Pair::BORDER, Pair::WHITE, 0) #white foreground, black background
#      Curses.init_pair(Pair::BORDER_FOCUS, Pair::MAGENTA, 0) #white foreground, black background
#
#      Curses.init_pair(Pair::TITLE, Pair::WHITE, 0) #white foreground, black background
#      Curses.init_pair(Pair::TITLE_FOCUS, Pair::WHITE, 0) #white foreground, black background

      Curses.init_pair(Pair::BLACK, Curses::COLOR_BLACK, 0) 
      Curses.init_pair(Pair::BLUE, Curses::COLOR_BLUE, 0) 
      Curses.init_pair(Pair::CYAN, Curses::COLOR_CYAN, 0) 
      Curses.init_pair(Pair::GREEN, Curses::COLOR_GREEN, 0) 
      Curses.init_pair(Pair::MAGENTA, Curses::COLOR_MAGENTA, 0) 
      Curses.init_pair(Pair::RED, Curses::COLOR_RED, 0)
      Curses.init_pair(Pair::WHITE, Pair::WHITE, 0)
      Curses.init_pair(Pair::YELLOW, Curses::COLOR_YELLOW, 0)
      Curses.init_pair(Pair::GRAY, Curses::COLOR_WHITE, 0)
    end

    def initialize(string_name)
      @color_pair = case string_name
               when "black"
                 Pair::BLACK
               when "blue"
                 Pair::BLUE
               when "cyan"
                 Pair::CYAN
               when "green"
                 Pair::GREEN
               when "magenta"
                 Pair::MAGENTA
               when "red"
                 Pair::RED
               when "white"
                 Pair::WHITE
               when "yellow"
                 Pair::YELLOW
               when "gray"
                 Pair::GRAY
               else
                 if string_name.to_i.to_s == string_name
                   string_name.to_i
                 else
                  Pair::WHITE
                 end
               end 
    end
  end
end
