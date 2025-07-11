---
sidebar_position: 2
---

# Keyboard Controls

Master Wassup's keyboard shortcuts for efficient navigation and interaction with your dashboard.

## Navigation Controls

### Basic Navigation

| Key | Action |
|-----|--------|
| `Tab` | Move to next pane |
| `Shift+Tab` | Move to previous pane |
| `↑` / `k` | Move up in pane content |
| `↓` / `j` | Move down in pane content |
| `Page Up` | Scroll up one page |
| `Page Down` | Scroll down one page |
| `Home` | Jump to top of pane |
| `End` | Jump to bottom of pane |

### Pane Selection

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Navigable Content"
  pane.highlight = true  # Enable keyboard navigation
  pane.interval = 60

  pane.content do |content|
    content.add_row("Row 1", { id: 1, data: "first" })
    content.add_row("Row 2", { id: 2, data: "second" })
    content.add_row("Row 3", { id: 3, data: "third" })
  end
  
  # Handle selection events
  pane.selection do |selected_data|
    puts "Selected: #{selected_data}"
  end
end
```

## Action Controls

### Selection and Interaction

| Key | Action |
|-----|--------|
| `Enter` / `Space` | Select current item |
| `Escape` | Cancel selection / Exit mode |
| `Delete` | Remove selected item (if supported) |
| `Insert` | Add new item (if supported) |

### Example: Interactive GitHub Issues

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'rails',
    repo: 'rails',
    query: 'is:issue is:open'
  )
  
  # Open selected issue in browser
  pane.selection do |issue|
    system("open #{issue['html_url']}")
  end
end
```

## Application Controls

### Global Commands

| Key | Action |
|-----|--------|
| `Ctrl+C` | Exit Wassup |
| `Ctrl+R` | Refresh all panes |
| `Ctrl+L` | Clear screen |
| `F5` | Force refresh current pane |
| `F1` | Show help |

### View Controls

| Key | Action |
|-----|--------|
| `+` | Increase font size |
| `-` | Decrease font size |
| `0` | Reset font size |
| `F11` | Toggle fullscreen |

## Search and Filter

### Quick Search

| Key | Action |
|-----|--------|
| `/` | Open search mode |
| `n` | Next search result |
| `N` | Previous search result |
| `Ctrl+F` | Find in current pane |

### Example: Searchable Content

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Searchable Logs"
  pane.highlight = true
  pane.searchable = true  # Enable search functionality
  pane.interval = 60

  pane.content do |content|
    # Large dataset that benefits from search
    logs = [
      "[INFO] Application started",
      "[ERROR] Database connection failed",
      "[WARN] High memory usage detected",
      "[INFO] User logged in",
      "[ERROR] API request timeout"
    ]
    
    logs.each do |log|
      content.add_row(log)
    end
  end
end
```

## Custom Keyboard Shortcuts

### Defining Custom Actions

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Custom Controls"
  pane.highlight = true
  pane.interval = 60

  pane.content do |content|
    content.add_row("Press 'r' to reload data")
    content.add_row("Press 'o' to open external tool")
    content.add_row("Press 'c' to copy selection")
  end
  
  # Custom keyboard handlers
  pane.key_handler('r') do
    # Reload data
    puts "Reloading data..."
  end
  
  pane.key_handler('o') do
    # Open external tool
    system("open https://github.com")
  end
  
  pane.key_handler('c') do |selected_data|
    # Copy to clipboard
    if selected_data
      system("echo '#{selected_data}' | pbcopy")
      puts "Copied to clipboard"
    end
  end
end
```

## Advanced Navigation

### Multi-Pane Layouts

For complex layouts with multiple panes, use these navigation patterns:

```ruby title="Supfile"
# Top pane (navigation with Tab)
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Quick Stats"
  pane.highlight = true
  pane.tab_order = 1  # First in tab order
  
  pane.content do |content|
    content.add_row("System Status: Online")
    content.add_row("Active Users: 42")
  end
end

# Middle pane
add_pane do |pane|
  pane.height = 0.4; pane.width = 0.6; pane.top = 0.3; pane.left = 0
  pane.title = "Main Content"
  pane.highlight = true
  pane.tab_order = 2  # Second in tab order
  
  pane.content do |content|
    content.add_row("Main application content")
  end
end

# Side pane
add_pane do |pane|
  pane.height = 0.4; pane.width = 0.4; pane.top = 0.3; pane.left = 0.6
  pane.title = "Side Panel"
  pane.highlight = true
  pane.tab_order = 3  # Third in tab order
  
  pane.content do |content|
    content.add_row("Side panel content")
  end
end

# Bottom pane
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0.7; pane.left = 0
  pane.title = "Footer"
  pane.highlight = true
  pane.tab_order = 4  # Fourth in tab order
  
  pane.content do |content|
    content.add_row("Footer information")
  end
end
```

## Mouse Support

### Mouse Interactions

| Action | Result |
|--------|--------|
| Click | Select pane |
| Double-click | Activate item |
| Scroll wheel | Scroll content |
| Right-click | Context menu (if available) |

### Enabling Mouse Support

```ruby title="Supfile"
# Enable mouse support globally
Wassup.configure do |config|
  config.mouse_support = true
  config.scroll_sensitivity = 3
end

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Mouse-Enabled Pane"
  pane.highlight = true
  pane.mouse_enabled = true
  pane.interval = 60

  pane.content do |content|
    (1..100).each do |i|
      content.add_row("Scrollable row #{i}")
    end
  end
end
```

## Accessibility Features

### Screen Reader Support

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Accessible Content"
  pane.highlight = true
  pane.accessibility = true  # Enable accessibility features
  pane.interval = 60

  pane.content do |content|
    # Use descriptive labels
    content.add_row("Critical alert: Database connection lost", {
      level: "critical",
      timestamp: Time.now,
      aria_label: "Critical system alert about database connectivity"
    })
    
    content.add_row("Information: 5 new messages", {
      level: "info",
      count: 5,
      aria_label: "Information notification about new messages"
    })
  end
end
```

## Keyboard Shortcuts Reference

### Quick Reference Card

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Keyboard Shortcuts"
  pane.highlight = true
  pane.static = true  # Static content, no refresh

  pane.content do |content|
    content.add_row("=== Navigation ===")
    content.add_row("Tab/Shift+Tab    - Switch panes")
    content.add_row("↑/↓, j/k         - Move up/down")
    content.add_row("Page Up/Down     - Scroll pages")
    content.add_row("Home/End         - Jump to top/bottom")
    content.add_row("")
    content.add_row("=== Actions ===")
    content.add_row("Enter/Space      - Select item")
    content.add_row("Escape           - Cancel")
    content.add_row("Delete           - Remove item")
    content.add_row("")
    content.add_row("=== Global ===")
    content.add_row("Ctrl+C           - Exit")
    content.add_row("Ctrl+R           - Refresh all")
    content.add_row("F5               - Refresh current")
    content.add_row("F1               - Show help")
    content.add_row("")
    content.add_row("=== Search ===")
    content.add_row("/                - Start search")
    content.add_row("n/N              - Next/Previous result")
    content.add_row("Ctrl+F           - Find in pane")
  end
end
```

## Tips and Best Practices

1. **Use Tab navigation** - Design your layout with logical tab order
2. **Enable highlighting** - Always set `highlight = true` for interactive panes
3. **Provide visual feedback** - Use colors and indicators for selected items
4. **Support both keyboard and mouse** - Accommodate different user preferences
5. **Add accessibility labels** - Include aria-labels for screen readers
6. **Test navigation flow** - Ensure smooth movement between panes
7. **Document custom shortcuts** - Include help text for custom key handlers

## Next Steps

- [Dashboard Layouts](../examples/dashboard-layouts.md) - Layout examples with keyboard navigation
- [Pane Properties](../configuration/pane-properties.md) - Configure pane behavior
- [Troubleshooting](../troubleshooting/common-issues.md) - Common keyboard control issues