---
sidebar_position: 1
---

# Pane Properties Reference

Complete reference for all pane configuration options in Wassup.

## Positioning Properties

### height
- **Type**: Float
- **Range**: 0.0 to 1.0
- **Default**: None (required)
- **Description**: Height of the pane as a percentage of the terminal height

```ruby
pane.height = 0.5    # Half terminal height
pane.height = 0.25   # Quarter terminal height
pane.height = 1.0    # Full terminal height
```

### width
- **Type**: Float
- **Range**: 0.0 to 1.0
- **Default**: None (required)
- **Description**: Width of the pane as a percentage of the terminal width

```ruby
pane.width = 0.5     # Half terminal width
pane.width = 0.33    # One third terminal width
pane.width = 1.0     # Full terminal width
```

### top
- **Type**: Float
- **Range**: 0.0 to 1.0
- **Default**: None (required)
- **Description**: Top position of the pane as a percentage from the top of the terminal

```ruby
pane.top = 0         # Top of terminal
pane.top = 0.5       # Middle of terminal
pane.top = 0.75      # Three quarters down
```

### left
- **Type**: Float
- **Range**: 0.0 to 1.0
- **Default**: None (required)
- **Description**: Left position of the pane as a percentage from the left of the terminal

```ruby
pane.left = 0        # Left edge of terminal
pane.left = 0.5      # Middle of terminal
pane.left = 0.66     # Two thirds to the right
```

## Display Properties

### title
- **Type**: String
- **Default**: None (optional)
- **Description**: Title displayed in the top border of the pane

```ruby
pane.title = "GitHub Pull Requests"
pane.title = "System Status"
pane.title = "CI/CD Pipeline"
```

### description
- **Type**: String
- **Default**: None (optional)
- **Description**: Description shown in help mode when user presses `?`

```ruby
pane.description = "Shows open pull requests for the team"
pane.description = "Monitors system health and performance"
```

### highlight
- **Type**: Boolean
- **Default**: `false`
- **Description**: Enable row highlighting and selection within the pane

```ruby
pane.highlight = true   # Enable selection
pane.highlight = false  # Display only (no interaction)
```

### show_refresh
- **Type**: Boolean
- **Default**: `false`
- **Description**: Show refresh animation indicator when pane is updating

```ruby
pane.show_refresh = true   # Show refresh indicator
pane.show_refresh = false  # No refresh indicator
```

### alert_level
- **Type**: AlertLevel enum
- **Default**: None (optional)
- **Description**: Visual alert level for the pane

```ruby
pane.alert_level = AlertLevel::HIGH     # Red border and "(X HIGH ALERTS)"
pane.alert_level = AlertLevel::MEDIUM   # Yellow border and "(X MEDIUM ALERTS)"
pane.alert_level = AlertLevel::LOW      # Cyan border and "(X LOW ALERTS)"
```

## Content Properties

### interval
- **Type**: Integer or Float
- **Default**: None (required for content blocks)
- **Description**: Refresh interval in seconds for the pane content

```ruby
pane.interval = 1        # Every second
pane.interval = 30       # Every 30 seconds
pane.interval = 60 * 5   # Every 5 minutes
pane.interval = 60 * 30  # Every 30 minutes
```

### content
- **Type**: Block
- **Default**: None (required unless using `type`)
- **Description**: Ruby block that defines the pane's content

```ruby
pane.content do |content|
  # Add rows to the pane
  content.add_row("Display text")
  content.add_row("Text with data", { id: 1, url: "https://example.com" })
end
```

### selection
- **Type**: Block
- **Default**: None (optional)
- **Description**: Ruby block that handles row selection actions

```ruby
# Default selection (Enter key)
pane.selection do |data|
  `open #{data[:url]}`
end

# Custom key bindings
pane.selection('o', 'Open in browser') do |data|
  `open #{data[:url]}`
end
```

### type
- **Type**: Pane Type Object
- **Default**: None (optional)
- **Description**: Built-in pane type for integrations

```ruby
pane.type = Panes::GitHub::PullRequests.new(org: 'myorg', repo: 'myrepo')
pane.type = Panes::CircleCI::Workflows.new(vcs: 'github', org: 'myorg', repo: 'myrepo')
```

## Content Methods

### add_row
Method available within the `content` block to add rows to the pane.

#### Basic Usage
```ruby
content.add_row("Simple text")
```

#### With Data
```ruby
content.add_row("Display text", { id: 1, url: "https://example.com" })
```

#### With Pages
```ruby
content.add_row("Page 1 content", data, page: "Page 1")
content.add_row("Page 2 content", data, page: "Page 2")
```

#### With Colors
```ruby
content.add_row("[fg=red]Error[fg=white] - Something went wrong")
content.add_row("[fg=green]Success[fg=white] - All good")
content.add_row("[fg=yellow]Warning[fg=white] - Check this")
```

### Available Colors
- `red` - Error states, critical alerts
- `green` - Success states, healthy status
- `yellow` - Warning states, attention needed
- `blue` - Information, neutral states
- `cyan` - Low priority alerts
- `magenta` - Special highlighting
- `white` - Default text color

## Selection Methods

### Default Selection
```ruby
pane.selection do |data|
  # Handle default selection (Enter key)
  puts "Selected: #{data}"
end
```

### Custom Key Bindings
```ruby
pane.selection('o', 'Open in browser') do |data|
  `open #{data[:url]}`
end

pane.selection('c', 'Copy to clipboard') do |data|
  `echo '#{data[:title]}' | pbcopy`
end

pane.selection('d', 'Delete item') do |data|
  # Custom deletion logic
end
```

## Built-in Pane Types

### GitHub Integration

#### Pull Requests
```ruby
pane.type = Panes::GitHub::PullRequests.new(
  org: 'organization',          # Required
  repo: 'repository',           # Required
  show_username: true,          # Optional, default: false
  show_interactions: true       # Optional, default: false
)
```

#### Releases
```ruby
pane.type = Panes::GitHub::Releases.new(
  org: 'organization',          # Required
  repo: 'repository'            # Required
)
```

#### Search
```ruby
pane.type = Panes::GitHub::Search.new(
  org: 'organization',          # Required
  repo: 'repository',           # Optional, nil = all org repos
  query: 'is:pr is:open',       # Required
  show_repo: true,              # Optional, default: false
  show_username: true,          # Optional, default: false
  show_interactions: true       # Optional, default: false
)
```

### CircleCI Integration

#### Workflows
```ruby
pane.type = Panes::CircleCI::Workflows.new(
  vcs: 'github',                # Required
  org: 'organization',          # Required
  repo: 'repository'            # Required
)
```

### Netlify Integration

#### Deploys
```ruby
pane.type = Panes::Netlify::Deploys.new(
  site_id: 'netlify-site-id'    # Required
)
```

### Shortcut Integration

#### Stories
```ruby
# Single query
pane.type = Panes::Shortcut::Stories.new(
  query: 'owner:username'       # Required
)

# Multiple queries as pages
pane.type = Panes::Shortcut::Stories.new(
  query_pages: {                # Required
    "Page 1": "query1",
    "Page 2": "query2"
  }
)
```

## Layout Examples

### Four-Pane Grid
```ruby
# Top-left
pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0

# Top-right
pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0.5

# Bottom-left
pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0

# Bottom-right
pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
```

### Three-Column Layout
```ruby
# Left column
pane.height = 1.0; pane.width = 0.33; pane.top = 0; pane.left = 0

# Middle column
pane.height = 1.0; pane.width = 0.33; pane.top = 0; pane.left = 0.33

# Right column
pane.height = 1.0; pane.width = 0.34; pane.top = 0; pane.left = 0.66
```

### Sidebar Layout
```ruby
# Left sidebar
pane.height = 1.0; pane.width = 0.2; pane.top = 0; pane.left = 0

# Main content area
pane.height = 1.0; pane.width = 0.8; pane.top = 0; pane.left = 0.2
```

### Stacked Layout
```ruby
# Top pane
pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0

# Middle pane
pane.height = 0.4; pane.width = 1.0; pane.top = 0.3; pane.left = 0

# Bottom pane
pane.height = 0.3; pane.width = 1.0; pane.top = 0.7; pane.left = 0
```

## Best Practices

### Positioning
- Always ensure `height + top ≤ 1.0`
- Always ensure `width + left ≤ 1.0`
- Use consistent spacing between panes
- Consider terminal minimum sizes

### Content
- Use appropriate refresh intervals
- Handle errors gracefully
- Provide meaningful row data
- Use color coding consistently

### Performance
- Avoid refreshing too frequently
- Use built-in pane types when possible
- Cache expensive operations
- Monitor API rate limits

### User Experience
- Provide clear pane titles
- Use descriptions for help mode
- Enable highlighting for interactive panes
- Implement meaningful selection actions

## Environment Variables

Some pane types require environment variables:

```bash
# GitHub integration
export WASSUP_GITHUB_USERNAME="your-username"
export WASSUP_GITHUB_ACCESS_TOKEN="your-token"

# CircleCI integration
export WASSUP_CIRCLE_CI_API_TOKEN="your-token"

# Netlify integration
export WASSUP_NETLIFY_TOKEN="your-token"

# Shortcut integration
export WASSUP_SHORTCUT_TOKEN="your-token"
```

## Next Steps

- [Dashboard Layout Examples](../examples/dashboard-layouts.md)
- [GitHub Integration](../integrations/github.md)
- [Keyboard Controls](../usage/keyboard-controls.md)
- [Troubleshooting](../troubleshooting/common-issues.md)