require 'curses'

require 'socket'
require 'time'

module Wassup
  class Pane
    attr_accessor :win
    attr_accessor :subwin
    attr_accessor :top

		attr_accessor :contents

    attr_accessor :title
    attr_accessor :description

    attr_accessor :alert_level

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
    attr_accessor :selection_blocks
    attr_accessor :selection_blocks_description

    attr_accessor :caught_error

    attr_accessor :content_thread
    attr_accessor :show_refresh

    attr_accessor :selected_view_index

    attr_accessor :win_height, :win_width, :win_top, :win_left

    attr_accessor :port

		class Content
			class Row
				attr_accessor :display
				attr_accessor :object

				def initialize(display, object)
					@display = display
					@object = object || display
				end
			end

			attr_accessor :title
			attr_accessor :data
      attr_accessor :alert_level

			def initialize(title = nil)
				@title = title
        @alert_level = nil
				@data = []	
			end

			def add_row(display, object = nil)
				@data << Row.new(display, object)
			end
		end

    def initialize(height, width, top, left, title: nil, description: nil, alert_level: nil, highlight: true, focus_number: nil, interval:, show_refresh:, content_block:, selection_blocks:, selection_blocks_description:, port: nil, debug: false)

      self.port = port

      if !debug
        self.win_height = Curses.lines * height	
        self.win_width = Curses.cols * width
        self.win_top = Curses.lines * top
        self.win_left = Curses.cols * left

        self.win = Curses::Window.new(self.win_height, self.win_width, self.win_top, self.win_left)
        self.setup_subwin()
      end

      self.focused = false
      self.focus_number = focus_number

      self.highlight = highlight
      self.virtual_scroll = true

      self.top = 0

			self.contents = []
      self.show_refresh = show_refresh
     
      self.selected_view_index = 0

      if !debug
        self.win.refresh
        self.subwin.refresh
      end

      self.title = title
      self.description = description

      self.alert_level = alert_level

      self.interval = interval
      self.content_block = content_block
      self.selection_blocks = selection_blocks || {}
      self.selection_blocks_description = selection_blocks_description || {}
    end

    def setup_subwin
      top_bump = 0

      unless self.subwin.nil?
        self.subwin.clear()
        self.subwin.close()
        self.subwin = nil
      end

      if (self.contents || []).size > 1
        top_bump = 4

        view_title = self.contents[self.selected_view_index].title || "<No Title>"
        view_title += " " * 100

        self.win.setpos(2, 2)
        self.win.addstr(view_title[0...self.win.maxx()-3])

        subtitle = "(#{self.selected_view_index + 1} out of #{self.contents.size})"
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

    def close
      unless self.subwin.nil?
        self.subwin.clear
        self.subwin.close
      end

      self.win.clear
      self.win.close
    end

    def needs_refresh?
      return false if self.content_block.nil?
      return false if self.interval.nil?
      return true if self.last_refreshed.nil?
      return Time.now - self.interval > self.last_refreshed
    end

    class Ope
      attr_accessor :error 
      def initialize(error)
        @error = error
      end
    end

		def data_lines
			return [] if self.selected_view_index.nil?
			content = (self.contents || [])[self.selected_view_index]

			if content.nil?
				return []
			else
				content.data.map(&:display)
			end
		end

		def refreshing?
			return !self.content_thread.nil?
		end

    def redraw
      self.update_box
      self.update_title
      self.load_current_view()
    end

    def refresh(force: false)
      if force
        self.last_refreshed = nil
      end

      if !needs_refresh?
        return
      end

      thread = self.content_thread
      if !thread.nil?
        if thread.status == "sleep" || thread.status == "run" || thread.status == "aborting"
          self.update_refresh
          return
        elsif thread.status == nil
          return
        elsif thread.status == false
          rtn = thread.value
          if rtn.is_a?(Ope)
            self.caught_error = rtn.error
						content = Wassup::Pane::Content.new("Overview")
            content.add_row("[fg=red]#{rtn.error.message}[fg=while]")
						content.add_row("")
						content.add_row("[fg=gray]Error at #{Time.now}[fg=while]")

						content_directions = Wassup::Pane::Content.new("Directions")
            content_directions.add_row("1. Press 'c' to copy the stacktrace")
            content_directions.add_row("2. Debug pane content block with:")
            content_directions.add_row("    $: wassup --debug")
            content_directions.add_row("3. Stacktrace viewable in next page")

						content_stacktrace = Wassup::Pane::Content.new("Stacktrace")
            rtn.error.backtrace.each do |line|
						  content_stacktrace.add_row(line)
            end

            self.refresh_content([content, content_directions, content_stacktrace])
          elsif rtn.is_a?(Wassup::PaneBuilder::ContentBuilder)
            self.caught_error = nil
            self.refresh_content(rtn.contents)
          end

					self.update_box
					self.update_title

          self.send_to_socket
        else
          # This shouldn't happen
          # TODO: also fix this
          return
        end
      else
        the_block = self.content_block
        self.content_thread = Thread.new {
          begin
						builder = Wassup::PaneBuilder::ContentBuilder.new(self.contents)
            content = the_block.call(builder)

						builder
          rescue => ex
            next Ope.new(ex)
          end
        }
				self.update_box
				self.update_title
      end
    end

    def refresh_content(contents)
      self.contents = contents

      self.load_current_view()
      self.last_refreshed = Time.now

      self.content_thread = nil
    end

    def load_current_view
      self.setup_subwin()

      # this might be bad
      self.highlighted_line = nil
			self.virtual_reload()
    end

    def title=(title)
      @title = title
      self.update_box()
      self.update_title()
    end

    def highlight
      if self.caught_error
        return true
      end 
      return @highlight
    end

    attr_accessor :refresh_char_count
    def refresh_char
      return "" unless self.show_refresh

      if self.refresh_char_count.nil?
        self.refresh_char_count = 0
      end

      if self.refreshing?
        array = ['\\', '|', '/', '|']
        rtn = array[self.refresh_char_count]

        self.refresh_char_count += 1
        if self.refresh_char_count >= array.size
          self.refresh_char_count = 0
        end

        return rtn
      else
        return ""
      end
    end

    attr_accessor :last_refresh_char_at
    def update_refresh
      return unless self.should_box

      self.last_refresh_char_at ||= Time.now

      if Time.now - self.last_refresh_char_at >= 0.15
        self.win.setpos(0, 1)
        self.win.addstr(self.refresh_char)
        self.win.refresh

        self.last_refresh_char_at = Time.now
      end
    end

    def send_to_socket
      return if self.port.nil?
      return if self.port.to_i == 0

      data = {
        title: self.title,
        description: self.description,
        alert_level: self.alert_level,
        alert_count: self.alert_count
      }

      sock = TCPSocket.new('127.0.0.1', self.port)
      sock.write(data.to_json)
      sock.close
    end

    def alert_count
      alert_count = 0
      if self.contents
        alert_count = self.contents.map { |c| c.data.size }.inject(0, :+)
      end

      return alert_count
    end
      
    def update_title
      return unless self.should_box

      title = self.title || "<No Title>"
      
      if self.focus_number.nil?
        full_title = title
      else 
        full_title = "#{self.focus_number} - #{title}"
      end
      full_title += " "

      self.win.setpos(0, 3)
      self.win.addstr(full_title)

      self.win.setpos(0, 3 + full_title.size)
      alert = ""
      alert_count = self.alert_count
      case self.alert_level
      when AlertLevel::HIGH
			  self.win.attrset(Curses.color_pair(Wassup::Color::Pair::RED))
        if alert_count == 1
          alert += "(#{alert_count} HIGH ALERT)"
        elsif alert_count > 0
          alert += "(#{alert_count} HIGH ALERTS)"
        end
      when AlertLevel::MEDIUM
			  self.win.attrset(Curses.color_pair(Wassup::Color::Pair::YELLOW))
        if alert_count == 1
          alert += "(#{alert_count} MEDIUM ALERT)"
        elsif alert_count > 0
          alert += "(#{alert_count} MEDIUM ALERTS)"
        end
      when AlertLevel::LOW
			  self.win.attrset(Curses.color_pair(Wassup::Color::Pair::CYAN))
        if alert_count == 1
          alert += "(#{alert_count} LOW ALERT)"
        elsif alert_count > 0
          alert += "(#{alert_count} LOW ALERTS)"
        end
      end
      self.win.addstr(alert)
			self.subwin.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))

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

      show_focused = self.focused

      if self.focus_number.nil?
        show_focused = true
      end

      self.win.attrset(show_focused ? Curses.color_pair(Wassup::Color::Pair::BORDER_FOCUS) : Curses.color_pair(Wassup::Color::Pair::BORDER))
      self.win.box()
      self.win.attrset(Curses.color_pair(Wassup::Color::Pair::NORMAL))

      self.win.refresh
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
      return if self.data_lines.nil? || self.data_lines.empty?

      # TODO: This errored out but might be because thread stuff???
      self.data_lines[self.top..(self.top+self.subwin.maxy-1)].each_with_index do |line, idx|

        write_full_line = false
        should_highlight = self.focused && self.highlight && (idx + self.top) == self.highlighted_line

        max_char = self.subwin.maxx()-3 
       
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
        self.selected_view_index = self.contents.size - 1
      end

      self.load_current_view
    end

    def scroll_right
      self.selected_view_index += 1
      if self.selected_view_index >= self.contents.size
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
          self.virtual_scroll_down
        else
          scroll_down
        end
      elsif input == "k"
        if virtual_scroll
          self.virtual_scroll_up
        else
          scroll_up
        end
      elsif input == "h"
        self.scroll_left
      elsif input == "l"
        self.scroll_right
      elsif input == "r"
        self.refresh(force: true)
      elsif input == "c"
        if !self.caught_error.nil?
          text = self.caught_error.backtrace.join("\n")
          if RUBY_PLATFORM.downcase =~ /win32/
            IO.popen('clip', 'w') { |pipe| pipe.puts text }
          else
            IO.popen('pbcopy', 'w') { |pipe| pipe.puts text }
          end
        end
      else
        selection_block = self.selection_blocks[input]
        if !selection_block.nil? && !self.highlighted_line.nil?
					content = self.contents[self.selected_view_index]
					row = content.data[self.highlighted_line]
					data = row.object || row.display
          selection_block.call(data)
        end
      end
    end
  end
end
