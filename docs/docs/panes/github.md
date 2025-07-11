# GitHub Panes

The GitHub panes allow you to display GitHub repository information directly in your Wassup dashboard. These panes provide real-time updates on pull requests, releases, and search results.

## Prerequisites

Before using GitHub panes, you need to set up GitHub authentication. See the [GitHub Setup Guide](../integrations/github/setup.md) for detailed instructions.

## Available GitHub Panes

### Pull Requests

Display pull requests for a specific repository.

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  
  pane.title = "Pull Requests"
  pane.interval = 300  # Update every 5 minutes
  
  pane.type = Wassup::Panes::GitHub::PullRequests.new(
    org: "your-org",
    repo: "your-repo",
    show_username: true,
    show_interactions: true
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `org` | String | Required | GitHub organization or username |
| `repo` | String | Required | Repository name |
| `show_username` | Boolean | `false` | Show the username of the PR author |
| `show_interactions` | Boolean | `false` | Show comment/review counts |

#### Keyboard Controls

- **Enter** - Open the selected pull request in your browser

### Releases

Display recent releases for a repository.

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  
  pane.title = "Releases"
  pane.interval = 3600  # Update every hour
  
  pane.type = Wassup::Panes::GitHub::Releases.new(
    org: "your-org",
    repo: "your-repo"
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `org` | String | Required | GitHub organization or username |
| `repo` | String | Required | Repository name |

#### Keyboard Controls

- **Enter** - Open the selected release in your browser

### Search

Search for issues and pull requests across repositories.

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0
  
  pane.title = "My Issues"
  pane.interval = 300  # Update every 5 minutes
  
  pane.type = Wassup::Panes::GitHub::Search.new(
    org: "your-org",
    repo: "your-repo",  # Optional - leave nil to search across org
    query: "assignee:@me is:open",
    show_repo: true,
    show_username: false,
    show_interactions: true
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `org` | String | Required | GitHub organization or username |
| `repo` | String | `nil` | Repository name (optional, searches across org if nil) |
| `query` | String | Required | GitHub search query |
| `show_repo` | Boolean | `true` | Show repository name in results |
| `show_username` | Boolean | `false` | Show the username of the author |
| `show_interactions` | Boolean | `false` | Show comment/review counts |

#### Common Search Queries

- `assignee:@me is:open` - Issues assigned to you
- `author:@me is:open` - Issues/PRs created by you
- `involves:@me is:open` - Issues/PRs involving you
- `is:pr is:open review-requested:@me` - PRs requesting your review
- `is:issue is:open label:bug` - Open bug issues
- `is:pr is:open draft:false` - Non-draft pull requests

#### Keyboard Controls

- **Enter** - Open the selected issue/PR in your browser

## Example Dashboard Layout

```ruby
# Top row - Pull requests and releases
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  
  pane.title = "PRs - Main Repo"
  pane.interval = 300
  
  pane.type = Wassup::Panes::GitHub::PullRequests.new(
    org: "your-org",
    repo: "main-repo",
    show_username: true,
    show_interactions: true
  )
end

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  
  pane.title = "Recent Releases"
  pane.interval = 3600
  
  pane.type = Wassup::Panes::GitHub::Releases.new(
    org: "your-org",
    repo: "main-repo"
  )
end

# Bottom row - Search results
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0
  
  pane.title = "My Tasks"
  pane.interval = 300
  
  pane.type = Wassup::Panes::GitHub::Search.new(
    org: "your-org",
    query: "assignee:@me is:open",
    show_repo: true,
    show_interactions: true
  )
end
```

## Rate Limiting

GitHub API has rate limits. The GitHub panes automatically handle rate limiting and will show appropriate messages when limits are reached. Consider:

- Using longer intervals for less critical panes
- Monitoring your API usage in your GitHub settings
- Using GitHub Apps for higher rate limits in organizations

## Troubleshooting

### Authentication Issues

If you're getting authentication errors:

1. Verify your GitHub token is set correctly
2. Check token permissions include repository access
3. Ensure the token hasn't expired

### Repository Not Found

If you get "repository not found" errors:

1. Verify the organization and repository names are correct
2. Check that your token has access to the repository
3. Ensure the repository exists and is accessible

For more troubleshooting tips, see the [GitHub Integration Guide](../integrations/github/setup.md).