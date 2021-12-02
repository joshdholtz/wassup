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

    attr_accessor :selected_view_index
    attr_accessor :all_view_data_objects

    attr_accessor :win_height, :win_width, :win_top, :win_left

    def initialize(height, width, top, left, title: nil, highlight: true, focus_number: nil, interval:, content_block:, selection_block:)
      self.win_height = Curses.lines * height	
      self.win_width = Curses.cols * width
      self.win_top = Curses.lines * top
      self.win_left = Curses.cols * left

      self.win = Curses::Window.new(self.win_height, self.win_width, self.win_top, self.win_left)
      self.setup_subwin()

      self.focused = false
      self.focus_number = focus_number

      self.highlight = highlight
      self.virtual_scroll = true

      self.top = 0
      self.data_lines = []
      self.data_objects = []
     
      self.selected_view_index = 0
      self.all_view_data_objects = [] # Array of array

      self.win.refresh
      self.subwin.refresh

      self.title = title

      self.interval = interval
      self.content_block = content_block
      self.selection_block = selection_block
    end

    def setup_subwin
      top_bump = 0

      unless self.subwin.nil?
        self.subwin.clear()
        self.subwin.close()
        self.subwin = nil
      end

      if (@all_view_data_objects || []).size > 1
        top_bump = 4

        view_title = (self.all_view_data_objects[self.selected_view_index] || {})[:title]
        view_title += " " * 100

        self.win.setpos(2, 2)
        self.win.addstr(view_title[0...self.win.maxx()-3])

        subtitle = "(#{self.selected_view_index + 1} out of #{self.all_view_data_objects.size})"
        subtitle += " " * 100
        self.win.setpos(3, 2)
        self.win.addstr(subtitle[0...self.win.maxx()-3])

        self.win.refresh
      end

      if self.win_height == 0
        self.should_box = false
        self.subwin = self.win.subwin(0, 0, 0, 0)
      else
        self.should_box = true
        self.subwin = self.win.subwin(self.win_height - 2 - top_bump, self.win_width - 4, self.win_top + 1 + top_bump, self.win_left + 2)
      end
      self.subwin.nodelay=true
      self.subwin.idlok(true)
      self.subwin.scrollok(true)
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

      return unless content.is_a?(Array)
      return if content.first.nil?

      if content.first.is_a?(Hash)
        self.all_view_data_objects = content
      else
        self.all_view_data_objects = [
          content
        ]
      end

      self.load_current_view()

      self.last_refreshed = Time.now
    end

    def load_current_view
      self.setup_subwin()
      view_content = self.all_view_data_objects[self.selected_view_index]

      # this might be bad
      self.highlighted_line = nil

      require 'pp'
      if view_content.is_a?(Hash) && view_content[:content]
        view_content = view_content[:content]
      end

      @data_lines = []
      @data_objects = []
      view_content.each do |item|
        if item.is_a?(String)
          @data_objects << item
          self.add_line(item)
        elsif item.is_a?(Array)
          @data_objects << item[1]
          self.add_line(item[0])
        end
      end
    end

    def title=(title)
      @title = title
      self.update_box()
      self.update_title()
    end
      
    def update_title
      return unless self.should_box

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
      self.virtual_reload()
    end

    def update_box
      return unless self.should_box

      self.win.attrset(self.focused ? Curses.color_pair(Wassup::Color::Pair::BORDER_FOCUS) : Curses.color_pair(Wassup::Color::Pair::BORDER))
      self.win.box()
      self.win.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))

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
      return if self.data_lines.nil?

      self.data_lines[self.top..(self.top+self.subwin.maxy-1)].each_with_index do |line, idx|

        write_full_line = false
        should_highlight = self.focused && self.highlight && (idx + self.top) == self.highlighted_line

        max_char = self.subwin.maxx()-3 
       
#        if false && write_full_line || should_highlight
#          if should_highlight
#            self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::HIGHLIGHT))
#          else
#            self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))
#          end
#
#          short_line = line[0...max_char]
#
#          self.subwin.setpos(idx, 0)
#          self.subwin.addstr(short_line)
#          self.subwin.clrtoeol()
#
#          self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))
#        else
          self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))

          splits = line.split(/\[.*?\]/) # returns ["hey something", "other thing", "okay"]
          scans = line.scan(/\[.*?\]/) #returns ["red", "white"]
          scans = scans.map do |str|
            if str.start_with?('[fg=')
              str = str.gsub('[fg=', '').gsub(']','')
              Wassup::Color.new(str)
            else
              str
            end
          end

          all_parts = splits.zip(scans).flatten.compact
      
          char_count = 0

          if should_highlight
            self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::HIGHLIGHT))
          end

          all_parts.each do |part|
            if part.is_a?(Wassup::Color)
              #color = Curses.color_pair([1,2,3,4].sample)
              if !should_highlight
                self.subwin.attrset(Curses.color_pair(part.color_pair))
              end
            else
              new_char_count = char_count + part.size
              if new_char_count >= max_char
                part = part[0...(max_char - char_count)]  
              end

              self.subwin.setpos(idx, char_count)
              self.subwin.addstr(part)

              char_count += part.size
            end

          end

          self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))
          self.subwin.clrtoeol()
        #end
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

    def scroll_left
      self.selected_view_index -= 1
      if self.selected_view_index < 0
        self.selected_view_index = self.all_view_data_objects.size - 1
      end

      self.load_current_view
    end

    def scroll_right
      self.selected_view_index += 1
      if self.selected_view_index >= self.all_view_data_objects.size
        self.selected_view_index = 0
      end

      self.load_current_view
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
          self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))
          self.subwin.setpos(self.subwin.maxy - 1, 0)
          self.subwin.addstr(str)
          self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))
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
        scroll_left
      elsif input == "l"
        scroll_right
      elsif input == "q"
        # TODO: This needs to quit
        # Need to kill the loop or something
      elsif input == 10 # enter
        if !self.selection_block.nil? && !self.highlighted_line.nil?
          data = @data_objects[self.highlighted_line]
          self.selection_block.call(data)
        end
      end
    end
  end
end
