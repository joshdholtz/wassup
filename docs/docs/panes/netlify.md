# Netlify Panes

The Netlify panes allow you to monitor your site deployments directly in your Wassup dashboard. Track deployment statuses, preview builds, and site health in real-time.

## Prerequisites

Before using Netlify panes, you need to set up Netlify authentication:

1. Get your Netlify API token from [Netlify User Settings](https://app.netlify.com/user/applications#personal-access-tokens)
2. Set the environment variable:
   ```bash
   export NETLIFY_API_TOKEN="your-token-here"
   ```

## Available Netlify Panes

### Deploys

Display recent deployments for a specific Netlify site.

```ruby
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Site Deployments"
  pane.interval = 300  # Update every 5 minutes
  
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "your-site-id"
  )
end
```

#### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `site_id` | String | Required | Netlify site ID (found in site settings) |

#### Finding Your Site ID

You can find your site ID in several ways:

1. **Netlify Dashboard**: Go to your site settings → General → Site details
2. **URL**: It's in the URL when viewing your site (e.g., `https://app.netlify.com/sites/your-site-id/`)
3. **API**: Use the Netlify API to list your sites

#### Deployment Display Information

The deploys pane shows:
- **Status** - Build status (success, building, error, etc.)
- **Branch** - The branch that was deployed
- **Commit** - Short commit hash and message
- **Deploy Time** - When the deployment was created
- **Build Duration** - How long the build took
- **Deploy URL** - The deployment URL (for previews)

#### Status Colors

- 🟢 **Green** - Successful deployments
- 🔴 **Red** - Failed deployments  
- 🟡 **Yellow** - Building/processing deployments
- 🔵 **Blue** - Ready deployments
- ⚪ **Gray** - Other states (queued, canceled, etc.)

#### Keyboard Controls

- **Enter** - Open the selected deployment in Netlify admin interface
- **o** - Open the deployment preview URL in your browser

## Example Configurations

### Single Site Monitoring

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Production Site"
  pane.interval = 180  # Update every 3 minutes
  
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "abc123def-456g-789h-ijkl-mnop123qrstu"
  )
end
```

### Multiple Sites Dashboard

```ruby
# Production site
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  
  pane.title = "Production"
  pane.interval = 180
  
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "prod-site-id"
  )
end

# Staging site
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0.5
  
  pane.title = "Staging"
  pane.interval = 120
  
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "staging-site-id"
  )
end

# Documentation site
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0
  
  pane.title = "Documentation"
  pane.interval = 300
  
  pane.type = Wassup::Panes::Netlify::Deploys.new(
    site_id: "docs-site-id"
  )
end
```

## Understanding Deployment Data

### Deployment States

Netlify deployments can have several states:

- **ready** - Deployment is live and accessible
- **building** - Currently building the site
- **error** - Build failed due to an error
- **processing** - Processing the built site
- **enqueued** - Waiting in the build queue
- **canceled** - Build was canceled
- **skipped** - Build was skipped (no changes)

### Deploy Types

- **Production Deploy** - Deploys to your main site URL
- **Deploy Preview** - Preview deploys for pull requests
- **Branch Deploy** - Deploys from specific branches

### Build Information

Each deployment shows:
- **Commit Information** - Hash, message, and author
- **Build Duration** - Time taken for the build process
- **Framework Detection** - Automatically detected framework
- **Build Command** - The command used to build the site

## Rate Limiting

Netlify API has rate limits:
- 500 requests per minute for personal tokens
- 1000 requests per minute for team tokens

The pane automatically handles rate limiting and will show appropriate messages when limits are reached.

## Troubleshooting

### Authentication Issues

If you're getting authentication errors:

1. Verify your Netlify API token is set correctly:
   ```bash
   echo $NETLIFY_API_TOKEN
   ```
2. Check that the token has the correct permissions
3. Ensure the token hasn't expired or been revoked

### Site Not Found

If you get "site not found" errors:

1. Verify the site ID is correct
2. Check that your token has access to the site
3. Ensure the site exists and is accessible to your account

### Common Issues

**No deployments showing:**
- Check if the site has any recent deployments
- Verify the site is properly configured in Netlify
- Ensure you have the correct site ID

**Slow updates:**
- Consider increasing the interval for less critical sites
- Monitor your API usage to avoid rate limits

**Permission errors:**
- Verify your Netlify token has access to the site
- Check if the site is part of a team you don't have access to

**Preview URLs not working:**
- Some deployments may not have preview URLs (production deploys)
- Check the deployment state - failed deployments won't have preview URLs
- Verify the site has preview deploys enabled

## Advanced Usage

### Monitoring Multiple Environments

You can create a comprehensive deployment monitoring setup:

```ruby
# Create a layout for different environments
environments = [
  { name: "Production", site_id: "prod-site-id", interval: 300 },
  { name: "Staging", site_id: "staging-site-id", interval: 180 },
  { name: "Development", site_id: "dev-site-id", interval: 120 }
]

environments.each_with_index do |env, index|
  add_pane do |pane|
    pane.height = 1.0 / environments.length
    pane.width = 1.0
    pane.top = index * (1.0 / environments.length)
    pane.left = 0
    
    pane.title = "#{env[:name]} Deploys"
    pane.interval = env[:interval]
    
    pane.type = Wassup::Panes::Netlify::Deploys.new(
      site_id: env[:site_id]
    )
  end
end
```

For more information about Netlify integration, see the [Netlify Setup Guide](../integrations/netlify/setup.md) or check the [Common Issues Guide](../troubleshooting/common-issues.md).