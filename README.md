<h3 align="center">
  <img height="200" alt="Wassup logo" src="https://user-images.githubusercontent.com/401294/145626927-7eb0fda5-c62a-47c8-9422-074b178fd8ef.png" />
</h3>

[![CI](https://github.com/joshdholtz/wassup/actions/workflows/ci.yml/badge.svg)](https://github.com/joshdholtz/wassup/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/fastlane/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/wassup.svg?style=flat)](https://rubygems.org/gems/wassup)

**Wassup** is a scriptable terminal dashboard that creates real-time, interactive displays of data from various sources. Configure panes and content logic in a `Supfile` and then run `wassup` to launch your customized dashboard.

## ✨ Features

- **📊 Multi-pane dashboard** with flexible grid layout
- **🔄 Real-time updates** with configurable refresh intervals
- **⌨️ Interactive navigation** with keyboard controls
- **🎨 Color-coded display** with alert levels
- **🚀 Built-in integrations** for GitHub, CircleCI, Netlify, and Shortcut
- **📄 Multi-page content** within individual panes
- **🛡️ Rate limiting** for API calls
- **🔧 Debug mode** for testing configurations
- **⚡ Performance optimizations** with battery-conscious updates

<hr/>

https://user-images.githubusercontent.com/401294/145632767-d75a8244-b68f-4838-8ff4-4017ba0c1ed2.mov

## 🚀 Quick Start

### Basic Custom Content

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.title = "Current Time"
  pane.interval = 1

  pane.content do |content|
    content.add_row(`date`)
  end
end
```

### GitHub Integration

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.title = "GitHub PRs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'fastlane',
    repo: 'fastlane',
    show_username: true,
    show_interactions: true
  )
end
```

### Custom API Content

```ruby
require 'json'
require 'rest-client'

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.highlight = true
  pane.title = "Open PRs - fastlane/fastlane"
  pane.interval = 60 * 5

  pane.content do |content|
    resp = RestClient.get "https://api.github.com/repos/fastlane/fastlane/pulls"
    json = JSON.parse(resp)
    json.each do |pr|
      display = "##{pr["number"]} #{pr["title"]}"
      content.add_row(display, pr["html_url"])
    end
  end
  
  pane.selection do |url|
    `open #{url}`
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wassup'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wassup

## 📋 Built-in Integrations

### GitHub

Monitor pull requests, releases, and search results across your repositories.

```ruby
# Pull Requests
pane.type = Panes::GitHub::PullRequests.new(
  org: 'organization',
  repo: 'repository',
  show_username: true,        # Show PR author
  show_interactions: true     # Show comments/reactions
)

# Releases
pane.type = Panes::GitHub::Releases.new(
  org: 'organization',
  repo: 'repository'
)

# Search
pane.type = Panes::GitHub::Search.new(
  org: 'organization',
  repo: 'repository',         # Optional - searches all org repos if nil
  query: 'is:pr is:open',     # GitHub search query
  show_repo: true,            # Show repository name
  show_username: true,        # Show author
  show_interactions: true     # Show interaction counts
)
```

### CircleCI

Monitor workflow status across your projects.

```ruby
pane.type = Panes::CircleCI::Workflows.new(
  vcs: 'github',
  org: 'organization',
  repo: 'repository'
)
```

### Netlify

Track deployment status for your sites.

```ruby
pane.type = Panes::Netlify::Deploys.new(
  site_id: 'your-netlify-site-id'
)
```

### Shortcut

Monitor stories and tasks in your project management.

```ruby
# Single query
pane.type = Panes::Shortcut::Stories.new(
  query: 'owner:username'
)

# Multiple queries as pages
pane.type = Panes::Shortcut::Stories.new(
  query_pages: {
    "My Stories": "owner:username",
    "Team Stories": "team:development",
    "In Progress": "state:\"In Progress\""
  }
)
```

## ⚙️ Configuration

### Pane Properties

| Property | Type | Description |
|----------|------|-------------|
| `height` | Float | Height as percentage of terminal (0.0 to 1.0) |
| `width` | Float | Width as percentage of terminal (0.0 to 1.0) |
| `top` | Float | Top position as percentage (0.0 to 1.0) |
| `left` | Float | Left position as percentage (0.0 to 1.0) |
| `title` | String | Pane title displayed in border |
| `description` | String | Description shown in help mode |
| `highlight` | Boolean | Enable row highlighting and selection |
| `interval` | Integer/Float | Refresh interval in seconds |
| `show_refresh` | Boolean | Show refresh animation |
| `alert_level` | AlertLevel | Alert level for visual emphasis |

### Alert Levels

```ruby
pane.alert_level = AlertLevel::HIGH     # Red - Critical alerts
pane.alert_level = AlertLevel::MEDIUM   # Yellow - Warnings
pane.alert_level = AlertLevel::LOW      # Cyan - Information
```

### Content and Selection

```ruby
pane.content do |content|
  # Add rows to display
  content.add_row("Display text", data_object)
  
  # Add rows to specific pages
  content.add_row("Page 1 content", data, page: "Page 1")
  content.add_row("Page 2 content", data, page: "Page 2")
  
  # Color-coded text
  content.add_row("[fg=red]Error[fg=white] - [fg=green]Success")
end

# Define selection actions
pane.selection do |selected_data|
  # Default action (Enter key)
  `open #{selected_data['url']}`
end

pane.selection('o', 'Open in browser') do |data|
  `open #{data['html_url']}`
end

pane.selection('c', 'Copy to clipboard') do |data|
  `echo '#{data['title']}' | pbcopy`
end
```

## 🔧 Environment Setup

### Required Environment Variables

```bash
# GitHub integration
export WASSUP_GITHUB_USERNAME="your-username"
export WASSUP_GITHUB_ACCESS_TOKEN="your-personal-access-token"

# CircleCI integration
export WASSUP_CIRCLE_CI_API_TOKEN="your-circleci-token"

# Netlify integration
export WASSUP_NETLIFY_TOKEN="your-netlify-token"

# Shortcut integration
export WASSUP_SHORTCUT_TOKEN="your-shortcut-token"
```

### GitHub Token Setup

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with these scopes:
   - `repo` - Full control of private repositories
   - `public_repo` - Access public repositories
   - `user` - Read user profile data

## 🎮 Keyboard Controls

| Key | Action |
|-----|--------|
| `1-9` | Focus specific panes |
| `j/k` | Move selection up/down |
| `h/l` | Navigate between pages |
| `Enter` | Execute selection action |
| `r` | Force refresh current pane |
| `?` | Show help |
| `q` | Quit |
| `c` | Copy error to clipboard (when error occurs) |

## 🚀 Usage

### Basic Usage

```bash
# Run with default Supfile
wassup

# Run with custom file
wassup MySupfile

# Debug mode to test individual panes
wassup --debug

# Run with socket port for external monitoring
wassup Supfile 8080
```

### Advanced Examples

#### Dashboard Layout

```ruby
# Top row - GitHub PRs and Releases
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0
  pane.title = "GitHub PRs"
  pane.type = Panes::GitHub::PullRequests.new(org: 'myorg', repo: 'myrepo')
end

add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0; pane.left = 0.5
  pane.title = "Releases"
  pane.type = Panes::GitHub::Releases.new(org: 'myorg', repo: 'myrepo')
end

# Bottom row - CircleCI and custom content
add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0
  pane.title = "CI Status"
  pane.type = Panes::CircleCI::Workflows.new(vcs: 'github', org: 'myorg', repo: 'myrepo')
end

add_pane do |pane|
  pane.height = 0.5; pane.width = 0.5; pane.top = 0.5; pane.left = 0.5
  pane.title = "System Status"
  pane.interval = 30
  pane.content do |content|
    uptime = `uptime`.strip
    load_avg = uptime.match(/load average: (.+)$/)[1]
    content.add_row("Load: #{load_avg}")
    content.add_row("Uptime: #{uptime}")
  end
end
```

#### Multi-page Content

```ruby
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Multi-page Dashboard"
  pane.highlight = true
  pane.interval = 60

  pane.content do |content|
    # GitHub PRs page
    github_prs = fetch_github_prs()
    github_prs.each do |pr|
      content.add_row("##{pr['number']} #{pr['title']}", pr, page: "GitHub PRs")
    end

    # CircleCI page
    workflows = fetch_circleci_workflows()
    workflows.each do |workflow|
      content.add_row("#{workflow['name']} - #{workflow['status']}", workflow, page: "CircleCI")
    end

    # System metrics page
    content.add_row("CPU: #{`top -l 1 | grep "CPU usage"`}", nil, page: "System")
    content.add_row("Memory: #{`top -l 1 | grep "PhysMem"`}", nil, page: "System")
  end
end
```

#### Error Handling with Alerts

```ruby
add_pane do |pane|
  pane.height = 0.5; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Service Status"
  pane.interval = 60
  pane.alert_level = AlertLevel::HIGH

  pane.content do |content|
    begin
      services = check_services()
      services.each do |service|
        status_color = service[:status] == 'up' ? 'green' : 'red'
        content.add_row("[fg=#{status_color}]#{service[:name]}: #{service[:status]}")
      end
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

## 🛠️ Troubleshooting

### Common Issues

#### API Rate Limiting
GitHub API has rate limits. Wassup includes built-in rate limiting:
- Authenticated requests: 5,000 per hour
- Search API: 30 requests per minute
- Rate limit information is displayed in debug mode

#### Authentication Errors
```bash
# Check if your tokens are set correctly
echo $WASSUP_GITHUB_ACCESS_TOKEN
echo $WASSUP_GITHUB_USERNAME

# Test token validity
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/user
```

#### Terminal Size Issues
Wassup requires a minimum terminal size. If panes appear corrupted:
1. Resize your terminal window
2. Press `r` to refresh the display
3. Check that your pane dimensions don't exceed 1.0

#### Debug Mode
Use debug mode to test individual panes:
```bash
wassup --debug
```

This will:
- Show detailed error messages
- Display API rate limit information
- Allow testing panes in isolation

### Performance Tips

#### Battery Optimization
Wassup includes battery-conscious updates:
- Longer refresh intervals when on battery power
- Reduced API calls during low battery
- Configurable performance settings

#### Memory Usage
For large datasets:
- Use pagination in your content blocks
- Limit the number of rows returned
- Consider using shorter refresh intervals for critical data only

## 🔧 Development

### Setup
```bash
git clone https://github.com/joshdholtz/wassup.git
cd wassup
bin/setup
```

### Running Tests
```bash
rake spec
```

### Interactive Console
```bash
bin/console
```

### Installation
```bash
# Install locally
bundle exec rake install

# Release new version
bundle exec rake release
```

### Creating New Pane Types

1. Create a new class in `lib/wassup/panes/`
2. Inherit from `Wassup::Pane`
3. Implement the required methods:
   - `content` - Returns the pane content
   - `selection` - Handles selection actions

Example:
```ruby
module Wassup
  module Panes
    module MyService
      class MyPane < Wassup::Pane
        def initialize(api_key:)
          @api_key = api_key
        end

        def content
          # Fetch and return content
        end

        def selection(data)
          # Handle selection
        end
      end
    end
  end
end
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Ways to Contribute

1. **Bug Reports** - Found a bug? [Open an issue](https://github.com/joshdholtz/wassup/issues)
2. **Feature Requests** - Have an idea? [Start a discussion](https://github.com/joshdholtz/wassup/discussions)
3. **Code Contributions** - Submit a pull request
4. **Documentation** - Help improve our docs
5. **New Integrations** - Add support for new services

### Development Guidelines

- Follow existing code style and patterns
- Add tests for new features
- Update documentation for new functionality
- Ensure all tests pass before submitting PR

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/joshdholtz/wassup/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Wassup project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wassup/blob/master/CODE_OF_CONDUCT.md).
