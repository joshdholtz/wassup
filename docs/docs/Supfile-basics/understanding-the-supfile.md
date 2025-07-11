---
sidebar_position: 1
---

# Understanding the `Supfile`

The `Supfile` is the heart of **Wassup**. It's a Ruby file that defines your dashboard layout and content. The dashboard is made up of **panes** that are configured through the `Supfile`.

## Basic Structure

Every `Supfile` contains one or more `add_pane` blocks that define individual panes:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.title = "Current Time"
  pane.interval = 1

  pane.content do |content|
    date = `date`
    content.add_row(date)
  end
end
```

## Pane Configuration

### Positioning Properties

| Property | Type | Range | Description |
|----------|------|-------|-------------|
| `height` | Float | 0.0 - 1.0 | Height as percentage of terminal |
| `width` | Float | 0.0 - 1.0 | Width as percentage of terminal |
| `top` | Float | 0.0 - 1.0 | Top position as percentage |
| `left` | Float | 0.0 - 1.0 | Left position as percentage |

### Display Properties

| Property | Type | Description |
|----------|------|-------------|
| `title` | String | Title displayed in the pane border |
| `description` | String | Description shown in help mode |
| `highlight` | Boolean | Enable row highlighting and selection |
| `show_refresh` | Boolean | Show refresh animation indicator |
| `alert_level` | AlertLevel | Visual alert level (HIGH, MEDIUM, LOW) |

### Content Properties

| Property | Type | Description |
|----------|------|-------------|
| `interval` | Integer/Float | Refresh interval in seconds |
| `content` | Block | Ruby block for generating pane content |
| `selection` | Block | Ruby block for handling row selection |
| `type` | Pane Type | Built-in pane type (GitHub, CircleCI, etc.) |

## Content Generation

The `content` block is where you define what data to display:

```ruby
pane.content do |content|
  # Add simple text rows
  content.add_row("Hello World")
  
  # Add rows with associated data
  content.add_row("Display Text", { id: 1, url: "https://example.com" })
  
  # Add rows to specific pages
  content.add_row("Page 1 content", data, page: "Page 1")
  content.add_row("Page 2 content", data, page: "Page 2")
  
  # Add color-coded rows
  content.add_row("[fg=red]Error[fg=white] - Something went wrong")
  content.add_row("[fg=green]Success[fg=white] - All good!")
end
```

## Selection Handling

Define how users can interact with your pane content:

```ruby
# Default selection (Enter key)
pane.selection do |data|
  `open #{data[:url]}`
end

# Custom key bindings
pane.selection('o', 'Open in browser') do |data|
  `open #{data[:url]}`
end

pane.selection('c', 'Copy to clipboard') do |data|
  `echo '#{data[:title]}' | pbcopy`
end
```

## Built-in Pane Types

Instead of writing custom content blocks, you can use built-in integrations:

```ruby
# GitHub Pull Requests
pane.type = Panes::GitHub::PullRequests.new(
  org: 'rails',
  repo: 'rails',
  show_username: true,
  show_interactions: true
)

# CircleCI Workflows
pane.type = Panes::CircleCI::Workflows.new(
  vcs: 'github',
  org: 'myorg',
  repo: 'myrepo'
)
```

## Multi-pane Layout Examples

### Four-pane Grid

```ruby
# Top-left: GitHub PRs
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "GitHub PRs"
  pane.type = Panes::GitHub::PullRequests.new(org: 'myorg', repo: 'myrepo')
end

# Top-right: CircleCI Status
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "CI Status"
  pane.type = Panes::CircleCI::Workflows.new(vcs: 'github', org: 'myorg', repo: 'myrepo')
end

# Bottom-left: System Info
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "System Info"
  pane.interval = 30
  pane.content do |content|
    content.add_row("Load: #{`uptime | grep -o 'load.*'`}")
    content.add_row("Memory: #{`free -h | grep Mem`}")
  end
end

# Bottom-right: Custom Content
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "Custom Data"
  pane.content do |content|
    content.add_row("Custom content here")
  end
end
```

### Sidebar Layout

```ruby
# Left sidebar: Navigation
add_pane do |pane|
  pane.height = 1.0; pane.width = 0.2; pane.top = 0; pane.left = 0
  pane.title = "Navigation"
  pane.highlight = true
  pane.content do |content|
    content.add_row("📊 Dashboard", { action: 'dashboard' })
    content.add_row("🔧 Settings", { action: 'settings' })
    content.add_row("📈 Analytics", { action: 'analytics' })
  end
end

# Main content area
add_pane do |pane|
  pane.height = 1.0; pane.width = 0.8; pane.top = 0; pane.left = 0.2
  pane.title = "Main Content"
  pane.type = Panes::GitHub::PullRequests.new(org: 'myorg', repo: 'myrepo')
end
```

## Error Handling

Handle errors gracefully in your content blocks:

```ruby
pane.content do |content|
  begin
    # API call or other operation
    data = fetch_external_data()
    data.each do |item|
      content.add_row(item[:title], item)
    end
  rescue => e
    content.add_row("[fg=red]Error: #{e.message}")
  end
end
```

## Performance Considerations

- Use appropriate refresh intervals (avoid refreshing too frequently)
- Limit the number of rows returned for large datasets
- Use caching for expensive operations
- Consider using built-in pane types for better performance

## Next Steps

- Learn about [GitHub Integration](../integrations/github.md)
- Explore [Advanced Examples](../examples/dashboard-layouts.md)
- Check the [Configuration Reference](../configuration/pane-properties.md)