---
sidebar_position: 1
---

# GitHub Setup

Configure GitHub integration for monitoring pull requests, releases, and search results.

## Authentication Setup

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

### Testing Your Setup

```bash
# Check if your tokens are set correctly
echo $WASSUP_GITHUB_USERNAME
echo $WASSUP_GITHUB_ACCESS_TOKEN

# Test token validity
curl -H "Authorization: token $WASSUP_GITHUB_ACCESS_TOKEN" https://api.github.com/user
```

## Quick Start

### Basic Pull Requests

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub PRs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.type = Panes::GitHub::PullRequests.new(
    org: 'rails',
    repo: 'rails'
  )
end
```

### Basic Issues Search

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

## Rate Limiting

GitHub API has rate limits that Wassup respects automatically:

- **Authenticated requests**: 5,000 per hour
- **Search API**: 30 requests per minute

### Monitor Rate Limits

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.3; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "GitHub Rate Limits"
  pane.interval = 60

  pane.content do |content|
    status = Wassup::Helpers::GitHub::RateLimiter.status
    
    content.add_row("Core API: #{status[:remaining]}/#{status[:limit]}")
    content.add_row("Reset at: #{status[:reset_at]}")
    content.add_row("Search API: #{status[:search_remaining]}")
    content.add_row("Queue size: #{status[:queue_size]}")
    
    remaining_pct = (status[:remaining].to_f / status[:limit].to_f) * 100
    
    if remaining_pct < 10
      content.add_row("[fg=red]⚠ Low rate limit remaining")
    elsif remaining_pct < 25
      content.add_row("[fg=yellow]⚠ Rate limit getting low")
    else
      content.add_row("[fg=green]✓ Rate limit OK")
    end
  end
end
```

## Next Steps

- [GitHub Helpers](./helpers.md) - Custom GitHub API helpers
- [GitHub Formatters](./formatters.md) - Formatting GitHub data
- [GitHub Examples](./examples.md) - Real-world GitHub configurations