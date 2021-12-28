require 'curses'

module Wassup
  class App
    def self.start(path:)
      Curses.init_screen
      Curses.start_color
      Curses.curs_set(0) # Invisible cursor
      Curses.noecho

      Curses.stdscr.scrollok true

      Wassup::Color.init

      # Determines the colors in the 'attron' below

      #Curses.init_pair(Curses::COLOR_BLUE,Curses::COLOR_BLUE,Curses::COLOR_BLACK) 
      #Curses.init_pair(Curses::COLOR_RED,Curses::COLOR_RED,Curses::COLOR_BLACK)

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
        description: pane_builder.description,
        highlight: pane_builder.highlight, 
        focus_number: number,
        interval: pane_builder.interval,
        show_refresh: pane_builder.show_refresh,
        content_block: pane_builder.content_block,
        selection_blocks: pane_builder.selection_blocks,
        selection_blocks_description: pane_builder.selection_blocks_description
      )
      pane.focus_handler = @focus_handler
      @panes[number.to_s] = pane
    end

    def initialize(path:)
      @hidden_pane = nil
      @help_pane = nil
      @focused_pane = nil
      @panes = {}

      @redraw_panes = false

      # TODO: this could maybe get replaced with selection_blocks now
      @focus_handler = Proc.new do |input|
        is_help_open = !@help_pane.nil?

        if input == "q"
          exit
        elsif is_help_open
          toggle_help
          next true
        elsif input == "?"
          toggle_help
          next true
        end

        next true if is_help_open

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
        @hidden_pane = Pane.new(0, 0, 0, 0, highlight: false, focus_number: 0, interval: nil, show_refresh: false, content_block: nil, selection_blocks: nil, selection_blocks_description: nil)
        @hidden_pane.focus_handler = @focus_handler
        @focused_pane = @hidden_pane

        eval(File.new(path).read)

        loop do
          @focused_pane.handle_keyboard

          if @redraw_panes
            Curses.clear
            Curses.refresh
          end

          # This isn't ideal to now refresh other panes when help is open
          # But it prevents things from getting drawn where the help is showing
          if @help_pane.nil?
            @panes.each do |id, pane|
              pane.redraw() if @redraw_panes
              pane.refresh()
            end
            @redraw_panes = false
          else
            @help_pane.refresh()
          end
        end
      ensure
        Curses.close_screen
      end
    end

    def row_help
      {
        "j" => "moves row highlight down",
        "k" => "moves row highlight up",
        "enter" => "perform selection on highlighted row"
      }
    end

    def page_help
      {
        "h" => "previous page in pane",
        "l" => "next page in pane"
      }
    end

    def toggle_help
      if @help_pane.nil?
        if @focused_pane == @hidden_pane
          content_block = Proc.new do |content|
            items = [
              "Welcome to Wassup!",
              "",
              "Press any number key to focus a pane",
              "",
              row_help.map { |k,v| "#{k} - #{v}"},
              "",
              page_help.map { |k,v| "#{k} - #{v}"},
              "",
              "? - opens help for focused pane"
            ].flatten

            items.each do |item|
              content.add_row(item)
            end
          end
        else
          content_block = Proc.new do |content|
            hash = {}

            hash = hash.merge(row_help)
            hash = hash.merge(@focused_pane.selection_blocks_description)

            row_help.map { |k,v| "#{k} - #{v}"}

            items = [
              @focused_pane.description,
              "",
              hash.map do |k,v|
                "#{k} - #{v}" 
              end,
              "",
              page_help.map { |k,v| "#{k} - #{v}"},
            ].flatten.compact

            items.each do |item|
              content.add_row(item)
            end
          end 
        end

        # Maybe find a way to add some a second border or an clear border to add more space to show its floating
        @help_pane = Pane.new(0.5, 0.5, 0.25, 0.25, title: "Help", highlight: false, focus_number: nil, interval: 100, show_refresh: false, content_block: content_block, selection_blocks: nil, selection_blocks_description: nil)
      else
        @help_pane.close
        @help_pane = nil 
        @redraw_panes = true
      end
    end
  end
end
