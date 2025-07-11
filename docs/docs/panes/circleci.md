# CircleCI Panes

The CircleCI panes allow you to monitor your continuous integration workflows directly in your Wassup dashboard. Track build statuses, workflow progress, and pipeline health in real-time.

## Prerequisites

Before using CircleCI panes, you need to set up CircleCI authentication:

1. Get your CircleCI API token from [CircleCI Personal API Tokens](https://app.circleci.com/settings/user/tokens)
2. Set the environment variable:
   ```bash
   export CIRCLECI_API_TOKEN="your-token-here"
   ```

## Available CircleCI Panes

### Workflows

Display recent workflow runs for a specific repository.

```ruby
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "CI Workflows"
  pane.interval = 180  # Update every 3 minutes
  
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-org",
    repo: "your-repo"
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `vcs` | String | Required | Version control system ("github" or "bitbucket") |
| `org` | String | Required | Organization or username |
| `repo` | String | Required | Repository name |

#### Workflow Display Information

The workflow pane shows:
- **Status** - Success, failed, running, or other workflow states
- **Branch** - The branch the workflow ran on
- **Workflow Name** - The name of the CircleCI workflow
- **Duration** - How long the workflow took to complete
- **Triggered By** - Who or what triggered the workflow
- **Timestamp** - When the workflow started

#### Status Colors

- 🟢 **Green** - Successful workflows
- 🔴 **Red** - Failed workflows
- 🟡 **Yellow** - Running workflows
- ⚪ **Gray** - Other states (queued, canceled, etc.)

#### Keyboard Controls

- **Enter** - Open the selected workflow in CircleCI web interface

## Example Configurations

### Single Repository Monitoring

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Main App CI"
  pane.interval = 120  # Update every 2 minutes
  
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-company",
    repo: "main-application"
  )
end
```

### Multiple Repository Dashboard

```ruby
# Frontend workflows
add_pane do |pane|
  pane.height = 0.33
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Frontend CI"
  pane.interval = 180
  
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-company",
    repo: "frontend-app"
  )
end

# Backend workflows
add_pane do |pane|
  pane.height = 0.33
  pane.width = 1.0
  pane.top = 0.33
  pane.left = 0
  
  pane.title = "Backend CI"
  pane.interval = 180
  
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-company",
    repo: "backend-api"
  )
end

# Mobile workflows
add_pane do |pane|
  pane.height = 0.34
  pane.width = 1.0
  pane.top = 0.66
  pane.left = 0
  
  pane.title = "Mobile CI"
  pane.interval = 180
  
  pane.type = Wassup::Panes::CircleCI::Workflows.new(
    vcs: "github",
    org: "your-company",
    repo: "mobile-app"
  )
end
```

## Understanding Workflow Data

### Workflow States

CircleCI workflows can have several states:

- **success** - All jobs completed successfully
- **failed** - One or more jobs failed
- **error** - Workflow encountered an error
- **running** - Workflow is currently executing
- **failing** - Workflow is running but has failed jobs
- **on_hold** - Workflow is paused waiting for approval
- **canceled** - Workflow was manually canceled
- **unauthorized** - Insufficient permissions

### Time Filtering

The CircleCI pane shows workflows from the last 14 days by default. This helps keep the display relevant and improves performance.

## Rate Limiting

CircleCI API has rate limits:
- 300 requests per minute for personal tokens
- Higher limits for organization tokens

The pane automatically handles rate limiting and will show appropriate messages when limits are reached.

## Troubleshooting

### Authentication Issues

If you're getting authentication errors:

1. Verify your CircleCI API token is set correctly:
   ```bash
   echo $CIRCLECI_API_TOKEN
   ```
2. Check that the token has the correct permissions
3. Ensure the token hasn't expired

### Repository Not Found

If you get "repository not found" errors:

1. Verify the VCS, organization, and repository names are correct
2. Check that your token has access to the repository
3. Ensure the repository is configured with CircleCI
4. Verify the repository has at least one workflow run

### Common Issues

**No workflows showing:**
- Check if the repository has any CircleCI workflows configured
- Verify workflows have run in the last 14 days
- Ensure the repository is properly connected to CircleCI

**Slow updates:**
- Consider increasing the interval for less critical repositories
- Monitor your API usage to avoid rate limits

**Permission errors:**
- Verify your CircleCI token has access to the organization
- Check if the repository is private and requires appropriate permissions

For more troubleshooting help, check the [CircleCI Integration Documentation](../integrations/circleci/) or the [Common Issues Guide](../troubleshooting/common-issues.md).