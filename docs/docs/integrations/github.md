---
sidebar_position: 1
---

# GitHub Integration

Monitor GitHub repositories, pull requests, issues, and development activity with comprehensive GitHub integration.

## Overview

The GitHub integration provides real-time monitoring of:
- Pull requests and reviews
- Issues and bug reports
- Repository activity and releases
- Team collaboration metrics
- Code search and discovery

## Quick Start

### Basic Repository Monitoring

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Activity"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
end
```

### Issue Tracking

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Open Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'rails',
    repo: 'rails',
    query: 'is:issue is:open'
  )
end
```

## Configuration

### Environment Variables

```bash
export WASSUP_GITHUB_USERNAME="your-username"
export WASSUP_GITHUB_ACCESS_TOKEN="your-personal-access-token"
```

### Authentication Setup

1. Create a GitHub Personal Access Token
2. Set the required environment variables
3. Configure your Supfile with GitHub panes

## GitHub Integration Components

### Setup & Authentication
- [GitHub Setup](./github/setup.md) - Complete authentication and configuration guide
- Environment variable configuration
- Token creation and management

### Advanced Features
- [GitHub Helpers](./github/helpers.md) - Custom API helpers and utilities
- [GitHub Formatters](./github/formatters.md) - Data formatting and display options
- [GitHub Examples](./github/examples.md) - Real-world configuration examples

## Available Panes

### Pull Requests
Monitor pull request activity across repositories.

```ruby title="Supfile"
pane.type = Panes::GitHub::PullRequests.new(
  org: 'your-org',
  repo: 'your-repo'
)
```

### Issues
Track issues and bug reports.

```ruby title="Supfile"
pane.type = Panes::GitHub::Issues.new(
  org: 'your-org',
  repo: 'your-repo'
)
```

### Repository Search
Search across GitHub repositories.

```ruby title="Supfile"
pane.type = Panes::GitHub::Search.new(
  org: 'your-org',
  repo: 'your-repo',
  query: 'is:pr is:open'
)
```

### Releases
Monitor repository releases and version updates.

```ruby title="Supfile"
pane.type = Panes::GitHub::Releases.new(
  org: 'your-org',
  repo: 'your-repo'
)
```

## Rate Limiting

GitHub API requests are automatically rate-limited to respect GitHub's limits:
- **Core API**: 5,000 requests per hour
- **Search API**: 30 requests per minute

Rate limiting is handled transparently with queuing and automatic retry logic.

## Next Steps

- [Setup GitHub Authentication](./github/setup.md)
- [Explore GitHub Helpers](./github/helpers.md)
- [View GitHub Examples](./github/examples.md)
- [Format GitHub Data](./github/formatters.md)