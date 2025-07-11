---
sidebar_position: 2
---

# Formatters & Styling

Learn how to format text, apply colors, and style your dashboard content for better readability and visual appeal.

## Text Formatting

### Basic Color Formatting

Wassup uses inline color codes to format text:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Color Examples"
  pane.interval = 60

  pane.content do |content|
    content.add_row("[fg=red]Red text")
    content.add_row("[fg=green]Green text")
    content.add_row("[fg=yellow]Yellow text")
    content.add_row("[fg=blue]Blue text")
    content.add_row("[fg=cyan]Cyan text")
    content.add_row("[fg=magenta]Magenta text")
    content.add_row("[fg=white]White text")
    
    # Mixed colors in one line
    content.add_row("[fg=red]Error: [fg=white]Connection failed to [fg=blue]api.example.com")
  end
end
```

### Status Indicators

Create consistent status indicators:

```ruby title="Supfile"
class StatusFormatter
  def self.success(message)
    "[fg=green]✓ #{message}"
  end
  
  def self.warning(message)
    "[fg=yellow]⚠ #{message}"
  end
  
  def self.error(message)
    "[fg=red]✗ #{message}"
  end
  
  def self.info(message)
    "[fg=blue]ℹ #{message}"
  end
  
  def self.pending(message)
    "[fg=cyan]⏳ #{message}"
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Status Indicators"
  pane.interval = 60

  pane.content do |content|
    content.add_row(StatusFormatter.success("All systems operational"))
    content.add_row(StatusFormatter.warning("Disk space low"))
    content.add_row(StatusFormatter.error("Database connection failed"))
    content.add_row(StatusFormatter.info("System maintenance scheduled"))
    content.add_row(StatusFormatter.pending("Deploying new version"))
  end
end
```

### Progress Bars

Create ASCII progress bars:

```ruby title="Supfile"
class ProgressFormatter
  def self.bar(percentage, width = 20)
    filled = (percentage / 100.0 * width).round
    empty = width - filled
    
    bar = "█" * filled + "░" * empty
    "#{bar} #{percentage.round(1)}%"
  end
  
  def self.colored_bar(percentage, width = 20)
    color = case percentage
    when 0..25 then 'red'
    when 26..50 then 'yellow'
    when 51..75 then 'cyan'
    else 'green'
    end
    
    "[fg=#{color}]#{bar(percentage, width)}"
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Progress Indicators"
  pane.interval = 5

  pane.content do |content|
    # Simulate various progress levels
    disk_usage = rand(100)
    memory_usage = rand(100)
    cpu_usage = rand(100)
    
    content.add_row("Disk Usage:   #{ProgressFormatter.colored_bar(disk_usage)}")
    content.add_row("Memory Usage: #{ProgressFormatter.colored_bar(memory_usage)}")
    content.add_row("CPU Usage:    #{ProgressFormatter.colored_bar(cpu_usage)}")
    
    # Custom width
    content.add_row("")
    content.add_row("Network: #{ProgressFormatter.colored_bar(rand(100), 30)}")
  end
end
```

### Data Tables

Format data in table-like structures:

```ruby title="Supfile"
class TableFormatter
  def self.format_table(data, headers = nil, widths = nil)
    return [] if data.empty?
    
    # Auto-detect column widths if not provided
    if widths.nil?
      widths = []
      if headers
        headers.each_with_index { |header, i| widths[i] = header.length }
      end
      
      data.each do |row|
        row.each_with_index do |cell, i|
          widths[i] = [widths[i] || 0, cell.to_s.length].max
        end
      end
    end
    
    result = []
    
    # Add header
    if headers
      header_row = headers.map.with_index { |h, i| h.ljust(widths[i]) }.join(" | ")
      result << header_row
      result << "-" * header_row.length
    end
    
    # Add data rows
    data.each do |row|
      formatted_row = row.map.with_index { |cell, i| cell.to_s.ljust(widths[i]) }.join(" | ")
      result << formatted_row
    end
    
    result
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Data Table"
  pane.interval = 60

  pane.content do |content|
    # Sample data
    data = [
      ['nginx', 'running', '1.2GB', '5%'],
      ['postgresql', 'running', '2.1GB', '12%'],
      ['redis', 'stopped', '0MB', '0%'],
      ['app-server', 'running', '800MB', '8%']
    ]
    
    headers = ['Service', 'Status', 'Memory', 'CPU']
    
    table = TableFormatter.format_table(data, headers)
    table.each { |row| content.add_row(row) }
  end
end
```

## Custom Formatters

### Number Formatting

```ruby title="Supfile"
class NumberFormatter
  def self.with_commas(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  
  def self.bytes_to_human(bytes)
    units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
    return '0 B' if bytes == 0
    
    exp = (Math.log(bytes) / Math.log(1024)).to_i
    exp = [exp, units.length - 1].min
    
    "#{(bytes.to_f / (1024 ** exp)).round(2)} #{units[exp]}"
  end
  
  def self.duration_to_human(seconds)
    return "#{seconds}s" if seconds < 60
    return "#{seconds / 60}m #{seconds % 60}s" if seconds < 3600
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60
    
    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{remaining_seconds}s" if remaining_seconds > 0
    
    parts.join(' ')
  end
  
  def self.percentage(value, total, decimals = 1)
    return "0%" if total == 0
    "#{((value.to_f / total.to_f) * 100).round(decimals)}%"
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Number Formatting"
  pane.interval = 60

  pane.content do |content|
    content.add_row("=== Large Numbers ===")
    content.add_row("Raw: 1234567")
    content.add_row("Formatted: #{NumberFormatter.with_commas(1234567)}")
    
    content.add_row("")
    content.add_row("=== File Sizes ===")
    [1024, 1048576, 1073741824, 1099511627776].each do |size|
      content.add_row("#{size} bytes = #{NumberFormatter.bytes_to_human(size)}")
    end
    
    content.add_row("")
    content.add_row("=== Durations ===")
    [30, 150, 3661, 90061].each do |duration|
      content.add_row("#{duration}s = #{NumberFormatter.duration_to_human(duration)}")
    end
    
    content.add_row("")
    content.add_row("=== Percentages ===")
    content.add_row("Progress: #{NumberFormatter.percentage(750, 1000)}")
    content.add_row("Accuracy: #{NumberFormatter.percentage(9876, 10000, 2)}")
  end
end
```

### Date and Time Formatting

```ruby title="Supfile"
class DateFormatter
  def self.relative_time(time)
    diff = Time.now - time
    
    case diff
    when 0..59
      "#{diff.to_i}s ago"
    when 60..3599
      "#{(diff / 60).to_i}m ago"
    when 3600..86399
      "#{(diff / 3600).to_i}h ago"
    when 86400..2591999
      "#{(diff / 86400).to_i}d ago"
    else
      time.strftime("%Y-%m-%d")
    end
  end
  
  def self.format_timestamp(time, format = :default)
    case format
    when :short
      time.strftime("%H:%M")
    when :date
      time.strftime("%Y-%m-%d")
    when :datetime
      time.strftime("%Y-%m-%d %H:%M:%S")
    when :relative
      relative_time(time)
    else
      time.strftime("%Y-%m-%d %H:%M")
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Date Formatting"
  pane.interval = 60

  pane.content do |content|
    now = Time.now
    past_times = [
      now - 30,      # 30 seconds ago
      now - 300,     # 5 minutes ago
      now - 3600,    # 1 hour ago
      now - 86400,   # 1 day ago
      now - 604800   # 1 week ago
    ]
    
    content.add_row("=== Current Time ===")
    content.add_row("Default: #{DateFormatter.format_timestamp(now)}")
    content.add_row("Short: #{DateFormatter.format_timestamp(now, :short)}")
    content.add_row("Date: #{DateFormatter.format_timestamp(now, :date)}")
    content.add_row("DateTime: #{DateFormatter.format_timestamp(now, :datetime)}")
    
    content.add_row("")
    content.add_row("=== Relative Times ===")
    past_times.each do |time|
      content.add_row("#{DateFormatter.format_timestamp(time, :relative)}")
    end
  end
end
```

### GitHub-specific Formatting

```ruby title="Supfile"
class GitHubFormatter
  def self.format_pr(pr, options = {})
    parts = []
    
    # PR number and title
    parts << "##{pr['number']}"
    parts << pr['title']
    
    # Author
    if options[:show_author]
      parts << "(@#{pr['user']['login']})"
    end
    
    # Interactions
    if options[:show_interactions]
      interactions = []
      if pr['comments'] && pr['comments'] > 0
        interactions << "💬 #{pr['comments']}"
      end
      if pr['review_comments'] && pr['review_comments'] > 0
        interactions << "📝 #{pr['review_comments']}"
      end
      parts << "(#{interactions.join(' ')})" unless interactions.empty?
    end
    
    # Status color
    if options[:colorize]
      case pr['state']
      when 'open'
        "[fg=green]#{parts.join(' ')}"
      when 'closed'
        "[fg=red]#{parts.join(' ')}"
      when 'merged'
        "[fg=blue]#{parts.join(' ')}"
      else
        parts.join(' ')
      end
    else
      parts.join(' ')
    end
  end
  
  def self.format_issue(issue, options = {})
    parts = []
    
    # Issue number and title
    parts << "##{issue['number']}"
    parts << issue['title']
    
    # Labels
    if options[:show_labels] && issue['labels'] && !issue['labels'].empty?
      labels = issue['labels'].map { |label| label['name'] }.join(', ')
      parts << "[#{labels}]"
    end
    
    # Author
    if options[:show_author]
      parts << "(@#{issue['user']['login']})"
    end
    
    # Comments
    if options[:show_comments] && issue['comments'] && issue['comments'] > 0
      parts << "(💬 #{issue['comments']})"
    end
    
    # Status color
    if options[:colorize]
      case issue['state']
      when 'open'
        "[fg=green]#{parts.join(' ')}"
      when 'closed'
        "[fg=red]#{parts.join(' ')}"
      else
        parts.join(' ')
      end
    else
      parts.join(' ')
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Formatting Examples"
  pane.interval = 60

  pane.content do |content|
    # Sample PR data
    sample_pr = {
      'number' => 1234,
      'title' => 'Add new feature for user authentication',
      'user' => { 'login' => 'developer' },
      'comments' => 5,
      'review_comments' => 3,
      'state' => 'open'
    }
    
    # Sample issue data
    sample_issue = {
      'number' => 567,
      'title' => 'Fix bug in login system',
      'user' => { 'login' => 'user123' },
      'comments' => 2,
      'labels' => [{ 'name' => 'bug' }, { 'name' => 'high-priority' }],
      'state' => 'open'
    }
    
    content.add_row("=== Pull Request Formatting ===")
    content.add_row("Basic: #{GitHubFormatter.format_pr(sample_pr)}")
    content.add_row("With author: #{GitHubFormatter.format_pr(sample_pr, show_author: true)}")
    content.add_row("With interactions: #{GitHubFormatter.format_pr(sample_pr, show_interactions: true)}")
    content.add_row("Colorized: #{GitHubFormatter.format_pr(sample_pr, colorize: true)}")
    content.add_row("Full: #{GitHubFormatter.format_pr(sample_pr, show_author: true, show_interactions: true, colorize: true)}")
    
    content.add_row("")
    content.add_row("=== Issue Formatting ===")
    content.add_row("Basic: #{GitHubFormatter.format_issue(sample_issue)}")
    content.add_row("With labels: #{GitHubFormatter.format_issue(sample_issue, show_labels: true)}")
    content.add_row("With author: #{GitHubFormatter.format_issue(sample_issue, show_author: true)}")
    content.add_row("With comments: #{GitHubFormatter.format_issue(sample_issue, show_comments: true)}")
    content.add_row("Full: #{GitHubFormatter.format_issue(sample_issue, show_labels: true, show_author: true, show_comments: true, colorize: true)}")
  end
end
```

## Text Alignment and Padding

### Alignment Utilities

```ruby title="Supfile"
class AlignmentFormatter
  def self.center(text, width)
    return text if text.length >= width
    
    padding = width - text.length
    left_pad = padding / 2
    right_pad = padding - left_pad
    
    " " * left_pad + text + " " * right_pad
  end
  
  def self.right_align(text, width)
    return text if text.length >= width
    
    padding = width - text.length
    " " * padding + text
  end
  
  def self.left_align(text, width)
    return text if text.length >= width
    
    padding = width - text.length
    text + " " * padding
  end
  
  def self.truncate(text, width, suffix = "...")
    return text if text.length <= width
    
    truncated_length = width - suffix.length
    text[0, truncated_length] + suffix
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Text Alignment"
  pane.interval = 60

  pane.content do |content|
    width = 40
    text = "Sample Text"
    
    content.add_row("=" * width)
    content.add_row(AlignmentFormatter.left_align(text, width))
    content.add_row(AlignmentFormatter.center(text, width))
    content.add_row(AlignmentFormatter.right_align(text, width))
    content.add_row("=" * width)
    
    content.add_row("")
    content.add_row("=== Truncation ===")
    long_text = "This is a very long text that needs to be truncated"
    content.add_row("Original: #{long_text}")
    content.add_row("Truncated: #{AlignmentFormatter.truncate(long_text, 30)}")
  end
end
```

### Advanced Formatting

```ruby title="Supfile"
class AdvancedFormatter
  def self.create_section(title, content_array, width = 50)
    result = []
    
    # Header
    result << "=" * width
    result << AlignmentFormatter.center(title.upcase, width)
    result << "=" * width
    
    # Content
    content_array.each do |line|
      result << AlignmentFormatter.left_align(line, width)
    end
    
    # Footer
    result << "=" * width
    
    result
  end
  
  def self.create_columns(left_content, right_content, total_width = 80)
    left_width = total_width / 2 - 2
    right_width = total_width - left_width - 4
    
    max_lines = [left_content.length, right_content.length].max
    result = []
    
    (0...max_lines).each do |i|
      left_text = left_content[i] || ""
      right_text = right_content[i] || ""
      
      left_formatted = AlignmentFormatter.left_align(left_text, left_width)
      right_formatted = AlignmentFormatter.left_align(right_text, right_width)
      
      result << "#{left_formatted} | #{right_formatted}"
    end
    
    result
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Advanced Formatting"
  pane.interval = 60

  pane.content do |content|
    # Section example
    section_content = [
      "System: Ubuntu 20.04",
      "Memory: 16GB",
      "CPU: Intel i7",
      "Disk: 1TB SSD"
    ]
    
    section = AdvancedFormatter.create_section("System Info", section_content)
    section.each { |line| content.add_row(line) }
    
    content.add_row("")
    
    # Column example
    left_column = [
      "Service",
      "nginx",
      "postgresql",
      "redis"
    ]
    
    right_column = [
      "Status",
      "running",
      "running",
      "stopped"
    ]
    
    columns = AdvancedFormatter.create_columns(left_column, right_column)
    columns.each { |line| content.add_row(line) }
  end
end
```

## Conditional Formatting

### Status-based Formatting

```ruby title="Supfile"
class ConditionalFormatter
  def self.format_status(status, message)
    case status.to_s.downcase
    when 'success', 'ok', 'healthy', 'up', 'running'
      "[fg=green]✓ #{message}"
    when 'warning', 'degraded', 'slow'
      "[fg=yellow]⚠ #{message}"
    when 'error', 'failed', 'down', 'stopped'
      "[fg=red]✗ #{message}"
    when 'pending', 'building', 'deploying'
      "[fg=cyan]⏳ #{message}"
    else
      "[fg=white]• #{message}"
    end
  end
  
  def self.format_metric(value, thresholds = {})
    warning_threshold = thresholds[:warning] || 75
    critical_threshold = thresholds[:critical] || 90
    
    if value >= critical_threshold
      "[fg=red]#{value}%"
    elsif value >= warning_threshold
      "[fg=yellow]#{value}%"
    else
      "[fg=green]#{value}%"
    end
  end
  
  def self.format_trend(current, previous)
    if current > previous
      "[fg=red]↑ #{current} (+#{current - previous})"
    elsif current < previous
      "[fg=green]↓ #{current} (-#{previous - current})"
    else
      "[fg=white]→ #{current} (no change)"
    end
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Conditional Formatting"
  pane.interval = 60

  pane.content do |content|
    # Status examples
    content.add_row("=== Status Formatting ===")
    statuses = ['success', 'warning', 'error', 'pending', 'unknown']
    statuses.each do |status|
      content.add_row(ConditionalFormatter.format_status(status, "Service #{status}"))
    end
    
    # Metric examples
    content.add_row("")
    content.add_row("=== Metric Formatting ===")
    metrics = [45, 78, 95]
    metrics.each do |metric|
      content.add_row("CPU Usage: #{ConditionalFormatter.format_metric(metric)}")
    end
    
    # Trend examples
    content.add_row("")
    content.add_row("=== Trend Formatting ===")
    trends = [[100, 95], [85, 90], [75, 75]]
    trends.each do |current, previous|
      content.add_row("Response Time: #{ConditionalFormatter.format_trend(current, previous)}")
    end
  end
end
```

## Best Practices

### Consistent Styling

```ruby title="Supfile"
# Define a consistent theme
module Theme
  COLORS = {
    success: 'green',
    warning: 'yellow',
    error: 'red',
    info: 'blue',
    muted: 'white'
  }
  
  ICONS = {
    success: '✓',
    warning: '⚠',
    error: '✗',
    info: 'ℹ',
    pending: '⏳',
    up: '↑',
    down: '↓',
    stable: '→'
  }
end

class ThemedFormatter
  def self.status(type, message)
    color = Theme::COLORS[type] || Theme::COLORS[:muted]
    icon = Theme::ICONS[type] || '•'
    
    "[fg=#{color}]#{icon} #{message}"
  end
  
  def self.metric(label, value, unit = '', status = :info)
    color = Theme::COLORS[status] || Theme::COLORS[:muted]
    "[fg=#{color}]#{label}: #{value}#{unit}"
  end
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Themed Formatting"
  pane.interval = 60

  pane.content do |content|
    content.add_row(ThemedFormatter.status(:success, "All services operational"))
    content.add_row(ThemedFormatter.status(:warning, "High memory usage"))
    content.add_row(ThemedFormatter.status(:error, "Database connection failed"))
    content.add_row(ThemedFormatter.status(:info, "System restart scheduled"))
    
    content.add_row("")
    content.add_row(ThemedFormatter.metric("CPU", "45", "%", :success))
    content.add_row(ThemedFormatter.metric("Memory", "78", "%", :warning))
    content.add_row(ThemedFormatter.metric("Disk", "95", "%", :error))
  end
end
```

## Next Steps

- [API Helpers](./api-helpers.md) - Working with APIs and data processing
- [Debug Mode](../debug/troubleshooting.md) - Testing and troubleshooting
- [Advanced Configuration](../advanced/complex-layouts.md) - Complex layouts and features