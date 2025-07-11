require 'time'

module Wassup
  module Panes
    class WorldClock
      attr_accessor :locations
      attr_accessor :sort_order
      attr_accessor :date_format
      attr_accessor :time_format
      attr_accessor :working_hours
      attr_accessor :color_coding

      def initialize(locations: {}, sort_order: 'natural', date_format: '%Y-%m-%d', time_format: '%H:%M:%S', working_hours: {start: 9, end: 17}, color_coding: true)
        @locations = locations
        @sort_order = sort_order
        @date_format = date_format
        @time_format = time_format
        @working_hours = working_hours
        @color_coding = color_coding
      end

      def configure(pane)
        pane.content do |content|
          now = Time.now
          
          # Build timezone data
          timezone_data = locations.map do |name, timezone|
            begin
              # Parse timezone and get current time
              tz_time = get_timezone_time(now, timezone)
              {
                name: name,
                timezone: timezone,
                time: tz_time,
                display_time: format_time_with_color(tz_time, tz_time.strftime(time_format)),
                display_date: tz_time.strftime(date_format)
              }
            rescue => e
              {
                name: name,
                timezone: timezone,
                time: nil,
                display_time: "[fg=red]Invalid TZ[fg=white]",
                display_date: "[fg=red]---[fg=white]"
              }
            end
          end

          # Sort according to sort_order
          case sort_order
          when 'alphabetical'
            timezone_data.sort_by! { |tz| tz[:name] }
          when 'chronological'
            timezone_data.sort_by! { |tz| tz[:time] || Time.at(0) }
          when 'reversechronological'
            timezone_data.sort_by! { |tz| tz[:time] || Time.at(0) }.reverse!
          when 'natural'
            # Keep original order
          end

          # Add header
          content.add_row("[fg=cyan]Location[fg=white]                  [fg=cyan]Time[fg=white]        [fg=cyan]Date[fg=white]")
          content.add_row("─" * 50)

          # Add timezone rows
          timezone_data.each do |tz|
            location_padded = tz[:name].ljust(20)
            time_padded = tz[:display_time].ljust(10)
            
            display_line = "#{location_padded} #{time_padded} #{tz[:display_date]}"
            content.add_row(display_line, tz)
          end

          # Add current refresh time
          content.add_row("")
          content.add_row("[fg=gray]Last updated: #{now.strftime('%H:%M:%S')}[fg=white]")
        end
      end

      private

      def get_work_hours_color(time)
        return 'white' unless color_coding
        
        hour = time.hour
        start_hour = working_hours[:start] || 9
        end_hour = working_hours[:end] || 17
        
        # Define transition zones (1 hour before/after work hours)
        pre_work_warning = start_hour - 1
        post_work_warning = end_hour + 1
        
        case hour
        when start_hour...end_hour
          # Core working hours - green
          'green'
        when pre_work_warning, post_work_warning
          # Close to start/end - yellow
          'yellow'
        else
          # Outside working hours - red
          'red'
        end
      end

      def format_time_with_color(time, formatted_time)
        return formatted_time unless color_coding
        
        color = get_work_hours_color(time)
        "[fg=#{color}]#{formatted_time}[fg=white]"
      end

      def get_timezone_time(base_time, timezone)
        # Try to use system timezone support first
        if timezone.match?(/^[A-Z][a-z]+\/[A-Z][a-z_]+/)
          # This is a TZ database name like "America/New_York"
          begin
            # Use Ruby's built-in timezone handling with ENV
            original_tz = ENV['TZ']
            ENV['TZ'] = timezone
            result = Time.at(base_time.to_i).localtime
            ENV['TZ'] = original_tz
            return result
          rescue
            # Fall back to offset calculation
            return base_time.getlocal(timezone_offset(timezone))
          end
        else
          # Handle offset format like "+01:00" or "-05:00"
          return base_time.getlocal(timezone_offset(timezone))
        end
      end

      def timezone_offset(timezone)
        # Handle common timezone formats
        case timezone
        when /^UTC$/i, /^GMT$/i
          '+00:00'
        when /^America\/New_York$/i
          # Eastern Time (UTC-5 or UTC-4 with DST)
          dst_active?(timezone) ? '-04:00' : '-05:00'
        when /^America\/Chicago$/i
          # Central Time (UTC-6 or UTC-5 with DST)
          dst_active?(timezone) ? '-05:00' : '-06:00'
        when /^America\/Denver$/i
          # Mountain Time (UTC-7 or UTC-6 with DST)
          dst_active?(timezone) ? '-06:00' : '-07:00'
        when /^America\/Los_Angeles$/i
          # Pacific Time (UTC-8 or UTC-7 with DST)
          dst_active?(timezone) ? '-07:00' : '-08:00'
        when /^Europe\/London$/i
          # GMT/BST (UTC+0 or UTC+1 with DST)
          dst_active?(timezone) ? '+01:00' : '+00:00'
        when /^Europe\/Paris$/i, /^Europe\/Berlin$/i, /^Europe\/Madrid$/i, /^Europe\/Warsaw$/i
          # Central European Time (UTC+1 or UTC+2 with DST)
          dst_active?(timezone) ? '+02:00' : '+01:00'
        when /^America\/Montevideo$/i
          # Uruguay Time (UTC-3, no DST currently)
          '-03:00'
        when /^Asia\/Tokyo$/i
          '+09:00'
        when /^Asia\/Dubai$/i
          '+04:00'
        when /^Asia\/Shanghai$/i
          '+08:00'
        when /^Australia\/Sydney$/i
          # AEST/AEDT (UTC+10 or UTC+11 with DST)
          dst_active?(timezone) ? '+11:00' : '+10:00'
        when /^[+-]\d{2}:\d{2}$/
          # Already in offset format
          timezone
        else
          # Try to parse as offset or default to UTC
          begin
            Time.parse("2000-01-01 12:00:00 #{timezone}").strftime('%z')
          rescue
            '+00:00'
          end
        end
      end

      def dst_active?(timezone)
        # Simplified DST detection - in a real implementation, 
        # you'd want to use a proper timezone library
        now = Time.now
        case timezone
        when /^America\//
          # US DST: second Sunday in March to first Sunday in November
          march_dst_start = second_sunday_of_march(now.year)
          november_dst_end = first_sunday_of_november(now.year)
          now >= march_dst_start && now < november_dst_end
        when /^Europe\//
          # EU DST: last Sunday in March to last Sunday in October
          march_dst_start = last_sunday_of_march(now.year)
          october_dst_end = last_sunday_of_october(now.year)
          now >= march_dst_start && now < october_dst_end
        when /^Australia\/Sydney$/
          # Australia DST: first Sunday in October to first Sunday in April
          october_dst_start = first_sunday_of_october(now.year)
          april_dst_end = first_sunday_of_april(now.year + 1)
          now >= october_dst_start || now < april_dst_end
        else
          false
        end
      end

      def second_sunday_of_march(year)
        march_1 = Time.new(year, 3, 1)
        first_sunday = march_1 + (7 - march_1.wday) % 7
        first_sunday + 7
      end

      def first_sunday_of_november(year)
        november_1 = Time.new(year, 11, 1)
        november_1 + (7 - november_1.wday) % 7
      end

      def last_sunday_of_march(year)
        march_31 = Time.new(year, 3, 31)
        march_31 - march_31.wday
      end

      def last_sunday_of_october(year)
        october_31 = Time.new(year, 10, 31)
        october_31 - october_31.wday
      end

      def first_sunday_of_october(year)
        october_1 = Time.new(year, 10, 1)
        october_1 + (7 - october_1.wday) % 7
      end

      def first_sunday_of_april(year)
        april_1 = Time.new(year, 4, 1)
        april_1 + (7 - april_1.wday) % 7
      end
    end
  end
end