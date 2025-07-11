---
sidebar_position: 1
---

# GitHub Integration

Wassup provides comprehensive GitHub integration to monitor pull requests, releases, and search results across your repositories.

## Setup

### Environment Variables

```bash
export WASSUP_GITHUB_USERNAME="your-username"
export WASSUP_GITHUB_ACCESS_TOKEN="your-personal-access-token"
```

### Creating a GitHub Token

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with these scopes:
   - `repo` - Full control of private repositories
   - `public_repo` - Access public repositories
   - `user` - Read user profile data

## Pull Requests

Monitor pull requests across your repositories with real-time updates.

### Basic Usage

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.title = "GitHub PRs"
  pane.highlight = true
  pane.interval = 60 * 5  # 5 minutes

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
end
```

### Configuration Options

```ruby
pane.type = Panes::GitHub::PullRequests.new(
  org: 'your-org',              # Required: GitHub organization
  repo: 'your-repo',            # Required: Repository name
  show_username: true,          # Optional: Show PR author (default: false)
  show_interactions: true       # Optional: Show comments/reactions (default: false)
)
```

### Display Format

- **Basic**: `#123 Add new feature`
- **With username**: `#123 Add new feature (@username)`
- **With interactions**: `#123 Add new feature (💬 5 👍 3)`
- **Full**: `#123 Add new feature (@username) (💬 5 👍 3)`

### Interactions

- **Enter**: Open PR in browser
- **o**: Open PR in browser (alternative)
- **c**: Copy PR URL to clipboard

## Releases

Track repository releases and version updates.

### Basic Usage

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5

  pane.title = "Latest Releases"
  pane.highlight = true
  pane.interval = 60 * 10  # 10 minutes

  pane.type = Panes::GitHub::Releases.new(
    org: 'rails',
    repo: 'rails'
  )
end
```

### Configuration Options

```ruby
pane.type = Panes::GitHub::Releases.new(
  org: 'your-org',              # Required: GitHub organization
  repo: 'your-repo'             # Required: Repository name
)
```

### Display Format

- Shows release version, date, and status
- Highlights pre-releases and drafts
- Color-codes release types

### Interactions

- **Enter**: Open release in browser
- **o**: Open release in browser (alternative)
- **c**: Copy release URL to clipboard

## Search

Search across repositories for issues, PRs, and code.

### Basic Usage

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0

  pane.title = "Open Issues"
  pane.highlight = true
  pane.interval = 60 * 5  # 5 minutes

  pane.type = Panes::GitHub::Search.new(
    org: 'rails',
    repo: 'rails',
    query: 'is:issue is:open'
  )
end
```

### Configuration Options

```ruby
pane.type = Panes::GitHub::Search.new(
  org: 'your-org',              # Required: GitHub organization
  repo: 'your-repo',            # Optional: Repository name (nil = all org repos)
  query: 'is:pr is:open',       # Required: GitHub search query
  show_repo: true,              # Optional: Show repository name (default: false)
  show_username: true,          # Optional: Show author (default: false)
  show_interactions: true       # Optional: Show comments/reactions (default: false)
)
```

### Search Query Examples

```ruby
# Open pull requests
query: 'is:pr is:open'

# Issues with specific labels
query: 'is:issue label:bug'

# PRs by author
query: 'is:pr author:username'

# Recently updated items
query: 'is:issue updated:>2024-01-01'

# Items with specific text
query: 'in:title "security fix"'

# Complex queries
query: 'is:pr is:open label:enhancement -label:wip'
```

### Multi-Repository Search

```ruby
# Search across all repositories in an organization
pane.type = Panes::GitHub::Search.new(
  org: 'rails',
  repo: nil,                    # Search all repos
  query: 'is:pr is:open',
  show_repo: true               # Show which repo each result is from
)
```

## Advanced Examples

### Team Dashboard

```ruby
# Team's open PRs
add_pane do |pane|
  pane.height = 0.33; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Team PRs"
  pane.highlight = true
  pane.interval = 60 * 3

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:pr is:open author:teammate1 author:teammate2 author:teammate3',
    show_repo: true,
    show_username: true,
    show_interactions: true
  )
end

# Issues assigned to team
add_pane do |pane|
  pane.height = 0.33; pane.width = 1.0; pane.top = 0.33; pane.left = 0
  pane.title = "Assigned Issues"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query: 'is:issue is:open assignee:teammate1 assignee:teammate2',
    show_repo: true
  )
end

# Recent releases
add_pane do |pane|
  pane.height = 0.34; pane.width = 1.0; pane.top = 0.66; pane.left = 0
  pane.title = "Recent Releases"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.type = Panes::GitHub::Releases.new(
    org: 'myorg',
    repo: 'main-product'
  )
end
```

### Multi-Repository Monitoring

```ruby
# Monitor PRs across multiple repositories
['frontend', 'backend', 'mobile'].each_with_index do |repo, index|
  add_pane do |pane|
    pane.height = 0.33
    pane.width = 1.0
    pane.top = index * 0.33
    pane.left = 0

    pane.title = "#{repo.capitalize} PRs"
    pane.highlight = true
    pane.interval = 60 * 5

    pane.type = Panes::GitHub::PullRequests.new(
      org: 'myorg',
      repo: repo,
      show_username: true,
      show_interactions: true
    )
  end
end
```

### Custom Search Pane

```ruby
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Multi-Search Dashboard"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::Search.new(
    org: 'myorg',
    query_pages: {
      "Open PRs": 'is:pr is:open',
      "My Issues": 'is:issue is:open assignee:@me',
      "Bug Reports": 'is:issue label:bug is:open',
      "Security": 'is:issue label:security',
      "Recent": 'is:issue updated:>2024-01-01'
    },
    show_repo: true,
    show_username: true
  )
end
```

## Rate Limiting

GitHub API has rate limits that Wassup respects:

- **Authenticated requests**: 5,000 per hour
- **Search API**: 30 requests per minute
- **Secondary rate limit**: Dynamic based on usage

### Built-in Rate Limiting

Wassup includes intelligent rate limiting:

```ruby
# Rate limiting is automatic, but you can see status in debug mode
wassup --debug
```

### Best Practices

1. **Use appropriate intervals**: Don't refresh too frequently
2. **Combine queries**: Use search instead of multiple individual requests
3. **Monitor usage**: Check rate limit status in debug mode
4. **Use caching**: Built-in for better performance

## Troubleshooting

### Common Issues

#### Authentication Failed
```bash
# Check your credentials
echo $WASSUP_GITHUB_USERNAME
echo $WASSUP_GITHUB_ACCESS_TOKEN

# Test token validity
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/user
```

#### Rate Limit Exceeded
```bash
# Check rate limit status
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/rate_limit
```

#### No Data Displayed
- Verify organization and repository names
- Check if repositories are public or if your token has appropriate access
- Ensure search queries return results

### Debug Mode

```bash
wassup --debug
```

This will show:
- API response details
- Rate limit information
- Error messages
- Request/response timing

## Next Steps

- [CircleCI Integration](./circleci.md)
- [Netlify Integration](./netlify.md)
- [Shortcut Integration](./shortcut.md)
- [Advanced Examples](../examples/dashboard-layouts.md)