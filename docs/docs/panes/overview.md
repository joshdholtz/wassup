# Prebuilt Panes Overview

Wassup comes with several prebuilt panes that integrate with popular development tools and services. These panes provide real-time information and allow you to interact with external services directly from your dashboard.

## Available Panes

### [GitHub](./github.md)
Monitor your GitHub repositories with real-time updates on pull requests, releases, and issues.

**Features:**
- Pull requests with review status
- Recent releases and tags
- Issue and PR search across repositories
- Direct browser integration

**Use Cases:**
- Code review monitoring
- Release tracking
- Issue management
- Team collaboration

### [CircleCI](./circleci.md)
Track your continuous integration workflows and build statuses.

**Features:**
- Workflow status monitoring
- Build duration tracking
- Branch-specific CI results
- Direct CircleCI integration

**Use Cases:**
- CI/CD monitoring
- Build failure alerts
- Deployment tracking
- Development workflow oversight

### [Netlify](./netlify.md)
Monitor your site deployments and build statuses.

**Features:**
- Deployment status tracking
- Build logs and errors
- Preview URL access
- Multi-site monitoring

**Use Cases:**
- Site deployment monitoring
- Build failure detection
- Preview environment management
- Static site workflow tracking

### [Shortcut](./shortcut.md)
Manage your project stories and track team progress.

**Features:**
- Story status monitoring
- Custom search queries
- Multi-page story views
- Story interaction

**Use Cases:**
- Sprint planning
- Story tracking
- Team progress monitoring
- Project management

### [World Clock](./world-clock.md)
Display multiple time zones with working hours color coding.

**Features:**
- Multiple timezone support
- Working hours visualization
- Flexible time/date formatting
- Smart DST handling

**Use Cases:**
- Distributed team coordination
- Meeting scheduling
- Global office hours
- Client timezone awareness

## Quick Start

### 1. Choose Your Panes

Select the panes that match your workflow:

```ruby
# Developer workflow
add_pane do |pane|
  pane.title = "Pull Requests"
  pane.type = Wassup::Panes::GitHub::PullRequests.new(
    org: "your-org",
    repo: "your-repo"
  )
end

add_pane do |pane|
  pane.title = "CI Status"
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-org",
    repo: "your-repo"
  )
end
```

### 2. Set Up Authentication

Most panes require API tokens:

```bash
# GitHub
export GITHUB_TOKEN="your-github-token"

# CircleCI
export CIRCLECI_API_TOKEN="your-circleci-token"

# Netlify
export NETLIFY_API_TOKEN="your-netlify-token"

# Shortcut
export SHORTCUT_API_TOKEN="your-shortcut-token"
```

### 3. Configure Your Layout

Arrange panes to fit your screen and workflow:

```ruby
# Top row - Development
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  pane.title = "PRs"
  pane.type = Wassup::Panes::GitHub::PullRequests.new(...)
end

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  pane.title = "Deployments"
  pane.type = Wassup::Panes::Netlify::Deploys.new(...)
end

# Bottom row - Project Management
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0.5
  pane.left = 0
  pane.title = "Stories"
  pane.type = Wassup::Panes::Shortcut::Stories.new(...)
end

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0.5
  pane.left = 0.5
  pane.title = "Team Times"
  pane.type = Wassup::Panes::WorldClock.new(...)
end
```

## Common Patterns

### Development Dashboard

Focus on code review and deployment monitoring:

```ruby
# Code review
add_pane do |pane|
  pane.title = "My PRs"
  pane.type = Wassup::Panes::GitHub::Search.new(
    org: "company",
    query: "author:@me is:open"
  )
end

# CI/CD status
add_pane do |pane|
  pane.title = "Build Status"
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "company",
    repo: "main-app"
  )
end

# Deployment status
add_pane do |pane|
  pane.title = "Live Site"
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "production-site-id"
  )
end
```

### Project Management Dashboard

Focus on story tracking and team coordination:

```ruby
# Personal stories
add_pane do |pane|
  pane.title = "My Stories"
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "owner:@me !is:done"
  )
end

# Team progress
add_pane do |pane|
  pane.title = "Sprint Progress"
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "iteration:current"
  )
end

# Team availability
add_pane do |pane|
  pane.title = "Team Times"
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "Alice (SF)" => "America/Los_Angeles",
      "Bob (NYC)" => "America/New_York",
      "Carol (London)" => "Europe/London"
    },
    working_hours: {start: 9, end: 17},
    color_coding: true
  )
end
```

### Operations Dashboard

Focus on system health and deployments:

```ruby
# Production deployments
add_pane do |pane|
  pane.title = "Production"
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "prod-site-id"
  )
end

# Staging deployments
add_pane do |pane|
  pane.title = "Staging"
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "staging-site-id"
  )
end

# CI health
add_pane do |pane|
  pane.title = "CI Status"
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "company",
    repo: "main-app"
  )
end

# Incident tracking
add_pane do |pane|
  pane.title = "Incidents"
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "label:incident !is:done"
  )
end
```

## Best Practices

### Refresh Intervals

Set appropriate refresh intervals based on importance:

```ruby
# Critical information - frequent updates
pane.interval = 60   # 1 minute

# Important information - moderate updates
pane.interval = 300  # 5 minutes

# Reference information - infrequent updates
pane.interval = 900  # 15 minutes
```

### API Rate Limits

Be mindful of API rate limits:

- **GitHub**: 5,000 requests per hour
- **CircleCI**: 300 requests per minute
- **Netlify**: 500 requests per minute
- **Shortcut**: 200 requests per minute

### Error Handling

All panes include built-in error handling:

- Network connectivity issues
- API rate limit exceeded
- Authentication failures
- Invalid configurations

Errors are displayed in the pane with helpful messages and retry logic.

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify API tokens are set correctly
   - Check token permissions
   - Ensure tokens haven't expired

2. **No Data Showing**
   - Verify service configuration
   - Check API connectivity
   - Review query parameters

3. **Performance Issues**
   - Increase refresh intervals
   - Reduce number of simultaneous panes
   - Monitor API usage

### Getting Help

- Check individual pane documentation for specific issues
- Review the [Common Issues Guide](../troubleshooting/common-issues.md)
- Verify service API status pages
- Test configurations in service web interfaces first

For more detailed information, see the individual pane documentation pages.