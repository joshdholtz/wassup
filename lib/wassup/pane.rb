require 'curses'

require 'time'

module Wassup
  class Pane
    attr_accessor :win
    attr_accessor :subwin
    attr_accessor :data_lines
    attr_accessor :data_objects
    attr_accessor :top

    attr_accessor :title

    attr_accessor :focused
    attr_accessor :focus_number

    attr_accessor :should_box

    attr_accessor :highlighted_line

    attr_accessor :highlight
    attr_accessor :virtual_scroll

    attr_accessor :focus_handler

    attr_accessor :interval
    attr_accessor :last_refreshed
    attr_accessor :content_block
    attr_accessor :selection_block

    def initialize(height, width, top, left, title: nil, highlight: true, focus_number: nil, interval:, content_block:, selection_block:)
      win_height = Curses.lines * height	
      win_width = Curses.cols * width
      win_top = top == 0 ? 0 : Curses.lines * top
      win_left = left == 0 ? 0 : Curses.cols * left

      self.win = Curses::Window.new(win_height, win_width, win_top, win_left)

      if height == 0
        self.should_box = false
        self.subwin = self.win.subwin(0, 0, 0, 0)
      else
        self.should_box = true
        self.subwin = self.win.subwin(win_height - 2, win_width - 4, win_top + 1, win_left + 2)
      end
      self.subwin.nodelay=true
      self.subwin.idlok(true)
      self.subwin.scrollok(true)

      self.focused = false
      self.focus_number = focus_number

      self.highlight = highlight
      self.virtual_scroll = true

      self.top = 0
      self.data_lines = []
      self.data_objects = []

      self.win.refresh
      self.subwin.refresh

      self.title = title

      self.interval = interval
      self.content_block = content_block
      self.selection_block = selection_block
    end

    def needs_refresh?
      return false if self.content_block.nil?
      return false if self.interval.nil?
      return true if self.last_refreshed.nil?
      return Time.now - self.interval > self.last_refreshed
    end

    def refresh
      return unless needs_refresh?

      content = self.content_block.call()
      @data_lines = []
      @data_objects = []
      content.each do |item|
        if item.is_a?(String)
          @data_objects << item
          self.add_line(item)
        elsif item.is_a?(Array)
          @data_objects << item[1]
          self.add_line(item[0])
        end

      end

      self.last_refreshed = Time.now
    end

    def title=(title)
      @title = title
      self.update_box()
      self.update_title()
    end
      
    def update_title
      title = self.title || "<No Title>"
      full_title = "#{self.focus_number} - #{title}"

      self.win.setpos(0, 3)
      self.win.addstr(full_title)
      self.win.refresh
    end

    def focused=(focused)
      @focused = focused
      self.update_box()
      self.update_title()
    end

    def update_box
      return unless self.should_box

      self.win.attron(self.focused ? Curses.color_pair(2) : Curses.color_pair(1))
      self.win.box()
      self.win.attron(Curses.color_pair(1))

      self.win.refresh
    end

    def add_line(text)
      data_lines << text

      if self.virtual_scroll
        self.virtual_reload
      else
        self.load_thing
      end
    end

    # Load the file into memory and
    # put the first part on the curses display.
    def load_thing
      self.data_lines[0..self.subwin.maxy-1].each_with_index do |line, idx|
        self.subwin.setpos(idx, 0)
        self.subwin.addstr(line)
      end
      self.subwin.setpos(0, 0)
      self.subwin.refresh
    end

    def virtual_reload
      self.data_lines[self.top..(self.top+self.subwin.maxy-1)].each_with_index do |line, idx|

        if self.highlight && (idx + self.top) == self.highlighted_line
          self.subwin.attron(Curses.color_pair(4))
        else
          self.subwin.attron(Curses.color_pair(1))
        end

        short_line = line[0...self.subwin.maxx()-5]

        self.subwin.setpos(idx, 0)
        self.subwin.addstr(short_line)
        self.subwin.clrtoeol()

        self.subwin.attron(Curses.color_pair(1))
      end
      self.subwin.refresh
    end

    def virtual_scroll_down
      self.update_highlight(1)

      bottom = self.top + self.subwin.maxy
      if bottom < self.data_lines.size
        # only move highlight and dont scroll if near top
        if !self.highlight || self.highlighted_line > highlight_scroll_padding
          self.top += 1
        end
      end

      self.virtual_reload
    end

    def highlight_scroll_padding
      return (self.subwin.maxy * 0.3).to_i
    end

    def virtual_scroll_up
      self.update_highlight(-1)

      if self.top > 0
        # only move highlight and dont scroll if near bottom
        if !self.highlight || (self.data_lines.size - self.highlighted_line) >= highlight_scroll_padding
          self.top -= 1
        end
      end

      self.virtual_reload
    end

    def update_highlight(inc)
      return unless self.highlight 

      prev = self.highlighted_line

      new = nil
      if prev.nil?
        new = 0
      elsif inc.nil?
        new = nil
      elsif !inc.nil?
        new = prev + inc
      end

      if new < 0 || new >= self.data_lines.size
        new = prev
      end

      self.highlighted_line = new

      return new
    end

    # Scroll the display up by one line.
    def scroll_up
      if self.top > 0
        self.subwin.scrl(-1)
        self.top -= 1
        str = self.data_lines[top]
        if str
          self.subwin.setpos(0, 0)
          self.subwin.addstr(str)
        end
        return true
      else
        return false
      end
    end

    # Scroll the display down by one line.
    def scroll_down
      if self.top + self.subwin.maxy < self.data_lines.length
        self.subwin.scrl(1)
        self.top += 1
        str = self.data_lines[self.top + self.subwin.maxy - 1]
        if str
          self.subwin.attron(Curses.color_pair(1))
          self.subwin.setpos(self.subwin.maxy - 1, 0)
          self.subwin.addstr(str)
          self.subwin.attron(Curses.color_pair(1))
        end
        return true
      else
        return false
      end
    end

    def handle_keyboard
      input = self.subwin.getch

      unless focus_handler.nil?
        handled = focus_handler.call(input)
        return if handled
      end

      if input == "j"
        if virtual_scroll
          virtual_scroll_down
        else
          scroll_down
        end
      elsif input == "k"
        if virtual_scroll
          virtual_scroll_up
        else
          scroll_up
        end
      elsif input == "h"
        require 'time'
        #add_line("#{Time.now}")
        add_line("line count: #{data_lines.size}")
      elsif input == 10 # enter
        if !self.selection_block.nil? && !self.highlighted_line.nil?
          data = @data_objects[self.highlighted_line]
          self.selection_block.call(data)
        end
      end
    end
  end
end
