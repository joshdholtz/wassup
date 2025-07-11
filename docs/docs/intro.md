---
sidebar_position: 1
---

# Introduction

**Wassup** is a scriptable terminal dashboard that creates real-time, interactive displays of data from various sources. This guide will help you get started with creating your first dashboard.

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

## 📦 Installation

Install **Wassup** from RubyGems:

```shell
gem install wassup
```

Or add to your `Gemfile`:

```ruby
source "https://rubygems.org"

gem "wassup"
```

Then run:

```shell
bundle install
```

## 🚀 Your First Dashboard

### Basic Example

Create a `Supfile` with the following contents:

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

Run `wassup` from your terminal in the same directory as your `Supfile`.

### Screenshot

You should see a pane in the top left corner that updates the time every second.

![Tutorial intro starter screenshot](/img/tutorial-intro-starter-screenshot.png)

### Interactive Example

Let's create a more interactive example with GitHub integration:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.6
  pane.width = 0.8
  pane.top = 0.2
  pane.left = 0.1

  pane.title = "GitHub Pull Requests"
  pane.highlight = true
  pane.interval = 60 * 5  # Refresh every 5 minutes

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails',
    show_username: true,
    show_interactions: true
  )
end
```

This creates an interactive pane that:
- Shows pull requests from the Rails repository
- Updates every 5 minutes
- Allows you to navigate with `j/k` keys
- Opens PRs in your browser when you press `Enter`

## 🔧 Environment Setup

For GitHub integration, you'll need to set up API credentials:

```bash
export WASSUP_GITHUB_USERNAME="your-username"
export WASSUP_GITHUB_ACCESS_TOKEN="your-personal-access-token"
```

### GitHub Token Setup

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with these scopes:
   - `repo` - Full control of private repositories
   - `public_repo` - Access public repositories
   - `user` - Read user profile data

## 🎮 Basic Controls

Once your dashboard is running, use these keyboard shortcuts:

| Key | Action |
|-----|--------|
| `j/k` | Move selection up/down |
| `Enter` | Execute selection action |
| `r` | Force refresh current pane |
| `?` | Show help |
| `q` | Quit |

## 🔄 What's Next?

Now that you have a basic dashboard running, explore these topics:

1. **[Simple Configuration](./basics/simple-configuration.md)** - Start with basic examples
2. **[Understanding the Supfile](./configuration/understanding-supfile.md)** - Learn about pane configuration
3. **[GitHub Integration](./integrations/github/setup.md)** - Connect to GitHub, CircleCI, Netlify, and Shortcut
4. **[Advanced Examples](./examples/dashboard-layouts.md)** - Create complex multi-pane dashboards
5. **[Configuration Reference](./configuration/pane-properties.md)** - Complete configuration options
