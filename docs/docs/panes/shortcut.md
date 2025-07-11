# Shortcut Panes

The Shortcut panes allow you to monitor your project management stories directly in your Wassup dashboard. Track story progress, assignments, and team workflow in real-time.

## Prerequisites

Before using Shortcut panes, you need to set up Shortcut authentication:

1. Get your Shortcut API token from [Shortcut Settings](https://app.shortcut.com/settings/api/tokens)
2. Set the environment variable:
   ```bash
   export SHORTCUT_API_TOKEN="your-token-here"
   ```

## Available Shortcut Panes

### Stories

Display stories based on search queries. This is the primary pane for monitoring Shortcut stories.

```ruby
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "My Stories"
  pane.interval = 300  # Update every 5 minutes
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "owner:me !is:done"
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `query` | String | Required | Shortcut search query |
| `query_pages` | Hash | `nil` | Multiple queries with page names |

#### Using Multiple Query Pages

You can display multiple search results in different pages within the same pane:

```ruby
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Team Stories"
  pane.interval = 300
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query_pages: {
      "My Stories" => "owner:me !is:done",
      "In Review" => "state:\"In Review\"",
      "Blocked" => "label:blocked !is:done",
      "This Week" => "created:>-7d"
    }
  )
end
```

#### Story Display Information

The stories pane shows:
- **Story ID** - Unique identifier (e.g., sc-1234)
- **Story Name** - Title of the story
- **Story Type** - Feature, bug, chore, etc.
- **State** - Current workflow state
- **Owner** - Assigned team member
- **Labels** - Associated labels
- **Points** - Story points estimate

#### Keyboard Controls

- **Enter** - Open the selected story in Shortcut web interface
- **h/l** - Navigate between query pages (if multiple pages configured)

## Common Search Queries

### Personal Queries

```ruby
# Stories assigned to you
"owner:me !is:done"

# Stories you created
"requester:me"

# Stories you're following
"follower:me"

# Stories waiting for your review
"owner:me state:\"In Review\""
```

### Team Queries

```ruby
# Stories in specific workflow state
"state:\"In Progress\""

# Stories with specific labels
"label:bug !is:done"

# Stories for specific team
"team:\"Engineering Team\""

# Stories in current iteration
"iteration:current"
```

### Time-based Queries

```ruby
# Stories created this week
"created:>-7d"

# Stories updated today
"updated:>-1d"

# Stories completed this month
"completed:>-30d"

# Stories due soon
"deadline:<7d"
```

### Priority and Estimation

```ruby
# High priority stories
"priority:high !is:done"

# Stories without points
"!has:points !is:done"

# Stories with specific point values
"points:3 !is:done"

# Unassigned stories
"!has:owner !is:done"
```

## Example Configurations

### Personal Dashboard

```ruby
# My active work
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  
  pane.title = "My Active Stories"
  pane.interval = 180
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "owner:me state:\"In Progress\""
  )
end

# My backlog
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  
  pane.title = "My Backlog"
  pane.interval = 300
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "owner:me state:\"Ready for Development\""
  )
end

# Stories waiting for review
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0
  
  pane.title = "Waiting for Review"
  pane.interval = 120
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "owner:me state:\"In Review\""
  )
end
```

### Team Dashboard

```ruby
# Team overview with multiple pages
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Team Overview"
  pane.interval = 300
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query_pages: {
      "In Progress" => "team:\"Engineering\" state:\"In Progress\"",
      "In Review" => "team:\"Engineering\" state:\"In Review\"",
      "Blocked" => "team:\"Engineering\" label:blocked !is:done",
      "Ready" => "team:\"Engineering\" state:\"Ready for Development\"",
      "Bugs" => "team:\"Engineering\" type:bug !is:done"
    }
  )
end
```

### Sprint/Iteration Monitoring

```ruby
# Current iteration
add_pane do |pane|
  pane.height = 0.4
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Current Sprint"
  pane.interval = 180
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "iteration:current"
  )
end

# Upcoming iteration
add_pane do |pane|
  pane.height = 0.3
  pane.width = 1.0
  pane.top = 0.4
  pane.left = 0
  
  pane.title = "Next Sprint"
  pane.interval = 600
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "iteration:next"
  )
end

# Recently completed
add_pane do |pane|
  pane.height = 0.3
  pane.width = 1.0
  pane.top = 0.7
  pane.left = 0
  
  pane.title = "Recently Completed"
  pane.interval = 3600
  
  pane.type = Wassup::Panes::Shortcut::Stories.new(
    query: "completed:>-7d"
  )
end
```

## Understanding Story Data

### Story Types

- **Feature** - New functionality
- **Bug** - Issues to fix
- **Chore** - Maintenance tasks
- **Epic** - Large features broken into smaller stories

### Workflow States

Shortcut allows custom workflow states, but common ones include:
- **Unscheduled** - Not yet planned
- **Ready for Development** - Ready to be worked on
- **In Progress** - Currently being worked on
- **In Review** - Under review/testing
- **Done** - Completed

### Story Points

- Used for estimation and planning
- Typically follow Fibonacci sequence (1, 2, 3, 5, 8, 13, 21)
- Help with sprint planning and capacity management

## Rate Limiting

Shortcut API has rate limits:
- 200 requests per minute for most endpoints
- Higher limits for premium accounts

The pane automatically handles rate limiting and will show appropriate messages when limits are reached.

## Troubleshooting

### Authentication Issues

If you're getting authentication errors:

1. Verify your Shortcut API token is set correctly:
   ```bash
   echo $SHORTCUT_API_TOKEN
   ```
2. Check that the token has the correct permissions
3. Ensure the token hasn't expired or been revoked

### No Stories Showing

If no stories are displayed:

1. Verify your search query is correct
2. Check that stories matching your query exist
3. Ensure your account has access to the stories
4. Test the query in Shortcut's web interface first

### Common Issues

**Query syntax errors:**
- Check Shortcut's search documentation for proper syntax
- Test queries in the Shortcut web interface before using in Wassup
- Common syntax: `field:value`, `!field:value` (not), `field:>value` (greater than)

**Permission errors:**
- Verify your API token has access to the workspace
- Check if stories are in projects you don't have access to

**Performance issues:**
- Consider using more specific queries to reduce result sets
- Increase intervals for less critical queries
- Monitor API usage to avoid rate limits

## Advanced Query Examples

### Complex Conditions

```ruby
# Stories assigned to me or my team, not done, high priority
"(owner:me OR team:\"My Team\") !is:done priority:high"

# Bugs created in the last week without owners
"type:bug created:>-7d !has:owner"

# Stories in specific project with points
"project:\"Mobile App\" has:points !is:done"
```

### Date Ranges

```ruby
# Stories created between specific dates
"created:2023-01-01..2023-01-31"

# Stories updated in the last 3 days
"updated:>-3d"

# Stories with deadlines this month
"deadline:2023-01-01..2023-01-31"
```

For more information about Shortcut integration and query syntax, see the [Shortcut API documentation](https://shortcut.com/api/rest/v3) or check the [Common Issues Guide](../troubleshooting/common-issues.md).