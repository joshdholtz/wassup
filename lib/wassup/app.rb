require 'curses'

module Wassup
  class App
    def self.start(path:)
      Curses.init_screen
      Curses.start_color
      Curses.curs_set(0) # Invisible cursor
      Curses.noecho

      Curses.stdscr.scrollok true

      Curses.init_pair(1, 15, 0) #white foreground, black background
      Curses.init_pair(2, 2, 0) # red foreground, black background
      Curses.init_pair(3, 7, 3) # white foreground, yellow background
      Curses.init_pair(4, 0, 15) # white foreground, yellow background

      app = App.new(path: path)
    end

    def add_pane
      pane_builder = Wassup::PaneBuilder.new
      yield(pane_builder)

      number = @panes.size + 1
      pane = Pane.new(
        pane_builder.height, 
        pane_builder.width, 
        pane_builder.top, 
        pane_builder.left, 
        title: pane_builder.title,
        highlight: pane_builder.highlight, 
        focus_number: number,
        interval: pane_builder.interval,
        content_block: pane_builder.content_block
      )
      pane.focus_handler = @focus_handler
      @panes[number.to_s] = pane
    end

    def initialize(path:)
      @hidden_pane = nil
      @focused_pane = nil
      @panes = {}

      @focus_handler = Proc.new do |input|
        if (pane = @panes[input.to_s])
          @focused_pane.focused = false

          if @focused_pane != pane
            @focused_pane = pane
            @focused_pane.focused = true
          else
            @focused_pane = @hidden_pane
          end

          true
        end

        if @focused_pane == @hidden_pane
          true
        else
          false
        end
      end

      begin

        @hidden_pane = Pane.new(0, 0, 0, 0, highlight: false, focus_number: 0, interval: nil, content_block: nil)
        @hidden_pane.focus_handler = @focus_handler
        @focused_pane = @hidden_pane

        eval(File.new(path).read)

        loop do
          @focused_pane.handle_keyboard
          @panes.each do |id, pane|
            pane.refresh()
          end
        end
      ensure
        Curses.close_screen
      end
    end
  end
end
