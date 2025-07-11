---
sidebar_position: 1
---

# Simple Configuration

Get started with Wassup using simple, straightforward configurations.

## Your First Pane

Create a `Supfile` with a basic time display:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  pane.title = "Current Time"
  pane.interval = 1

  pane.content do |content|
    content.add_row(Time.now.strftime("%Y-%m-%d %H:%M:%S"))
  end
end
```

## Basic System Information

Display system stats:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  pane.title = "System Info"
  pane.interval = 30

  pane.content do |content|
    content.add_row("Hostname: #{`hostname`.strip}")
    content.add_row("Uptime: #{`uptime`.strip}")
    content.add_row("Date: #{Time.now}")
    
    # Simple disk usage
    disk_usage = `df -h / | tail -1`.strip
    content.add_row("Disk: #{disk_usage}")
  end
end
```

## Two-Pane Layout

Split your screen into two sections:

```ruby title="Supfile"
# Left pane - Clock
add_pane do |pane|
  pane.height = 1.0
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  pane.title = "Clock"
  pane.interval = 1

  pane.content do |content|
    content.add_row(Time.now.strftime("%H:%M:%S"))
    content.add_row(Time.now.strftime("%Y-%m-%d"))
    content.add_row(Time.now.strftime("%A"))
  end
end

# Right pane - System load
add_pane do |pane|
  pane.height = 1.0
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  pane.title = "System Load"
  pane.interval = 10

  pane.content do |content|
    load_avg = `uptime | grep -o 'load average.*'`.strip
    content.add_row(load_avg)
    
    # Memory usage (macOS)
    memory = `top -l 1 | grep PhysMem`.strip
    content.add_row(memory)
  end
end
```

## Simple Interactive Pane

Create a pane with selectable items:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  pane.title = "Quick Actions"
  pane.highlight = true  # Enable selection
  pane.interval = 60

  pane.content do |content|
    content.add_row("📁 Open Documents", { action: "open", path: "~/Documents" })
    content.add_row("📂 Open Downloads", { action: "open", path: "~/Downloads" })
    content.add_row("🌐 Open GitHub", { action: "url", url: "https://github.com" })
    content.add_row("⚙️ System Preferences", { action: "open", path: "/System/Applications/System Preferences.app" })
  end

  pane.selection do |data|
    case data[:action]
    when "open"
      `open #{data[:path]}`
    when "url"
      `open #{data[:url]}`
    end
  end
end
```

## Essential Properties

### Required Properties
Every pane needs these four positioning properties:

```ruby
pane.height = 0.5  # Height as percentage (0.0 to 1.0)
pane.width = 0.5   # Width as percentage (0.0 to 1.0)
pane.top = 0       # Top position (0.0 to 1.0)
pane.left = 0      # Left position (0.0 to 1.0)
```

### Common Properties
```ruby
pane.title = "My Pane"        # Pane title
pane.interval = 60            # Refresh every 60 seconds
pane.highlight = true         # Enable row selection
pane.show_refresh = true      # Show refresh indicator
```

## Basic Colors

Add simple color coding to your content:

```ruby
pane.content do |content|
  content.add_row("[fg=green]✓ Success - All systems operational")
  content.add_row("[fg=yellow]⚠ Warning - Check disk space")
  content.add_row("[fg=red]✗ Error - Service unavailable")
  content.add_row("[fg=white]ℹ Info - Regular status update")
end
```

Available colors: `red`, `green`, `yellow`, `blue`, `cyan`, `magenta`, `white`

## Simple File Monitoring

Monitor log files or configuration files:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  pane.title = "Recent Activity"
  pane.interval = 10

  pane.content do |content|
    # Last 10 lines of a log file
    if File.exist?('/var/log/system.log')
      logs = `tail -10 /var/log/system.log`
      logs.split("\n").each do |line|
        content.add_row(line)
      end
    else
      content.add_row("No log file found")
    end
  end
end
```

## Running Your Configuration

1. Save your configuration as `Supfile`
2. Run in your terminal:
   ```bash
   gem install wassup
   wassup
   ```

## Basic Controls

- **j/k** - Move up/down in highlighted panes
- **Enter** - Select highlighted item
- **r** - Refresh current pane
- **q** - Quit
- **?** - Show help

## Common Layouts

### Full Screen
```ruby
pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
```

### Half Screen (Left)
```ruby
pane.height = 1.0; pane.width = 0.5; pane.top = 0; pane.left = 0
```

### Half Screen (Right)
```ruby
pane.height = 1.0; pane.width = 0.5; pane.top = 0; pane.left = 0.5
```

### Quarter Screen (Top-Left)
```ruby
pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0
```

### Quarter Screen (Top-Right)
```ruby
pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0.5
```

### Quarter Screen (Bottom-Left)
```ruby
pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0
```

### Quarter Screen (Bottom-Right)
```ruby
pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
```

## Next Steps

- [Advanced Configuration](../advanced/complex-layouts.md) - Multi-pane layouts and advanced features
- [Built-in Integrations](../integrations/github.md) - GitHub, CircleCI, Netlify, and more
- [Debug Mode](../debug/troubleshooting.md) - Testing and troubleshooting your configuration