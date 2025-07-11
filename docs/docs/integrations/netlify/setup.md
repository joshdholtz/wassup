---
sidebar_position: 1
---

# Netlify Setup

Configure Netlify integration for monitoring deployments, build status, and site analytics.

## Overview

The Netlify integration provides real-time monitoring of:
- Site deployments and build status
- Form submissions and analytics
- Site performance metrics
- Build logs and errors

## Authentication Setup

### Environment Variables

```bash
export WASSUP_NETLIFY_ACCESS_TOKEN="your-netlify-access-token"
export WASSUP_NETLIFY_SITE_ID="your-site-id"  # Optional: for single-site monitoring
```

### Creating a Netlify Access Token

1. Go to [Netlify User Settings → Applications](https://app.netlify.com/user/applications)
2. Click "New access token"
3. Give it a descriptive name (e.g., "Wassup Dashboard")
4. Copy the generated token

### Finding Your Site ID

```bash
# Using Netlify CLI
netlify sites:list

# Or find it in the Netlify dashboard URL
# https://app.netlify.com/sites/YOUR-SITE-ID/overview
```

### Testing Your Setup

```bash
# Test token validity
curl -H "Authorization: Bearer $WASSUP_NETLIFY_ACCESS_TOKEN" \
  https://api.netlify.com/api/v1/user

# Test site access
curl -H "Authorization: Bearer $WASSUP_NETLIFY_ACCESS_TOKEN" \
  https://api.netlify.com/api/v1/sites/$WASSUP_NETLIFY_SITE_ID
```

## Quick Start

### Basic Site Monitoring

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Netlify Site Status"
  pane.highlight = true
  pane.interval = 60 * 2

  pane.type = Panes::Netlify::Sites.new
end
```

### Deployment Status

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Recent Deployments"
  pane.highlight = true
  pane.interval = 60 * 3

  pane.type = Panes::Netlify::Deployments.new(
    site_id: ENV['WASSUP_NETLIFY_SITE_ID']
  )
end
```

## Configuration Options

### Multi-Site Dashboard

```ruby title="Supfile"
# Monitor multiple sites
NETLIFY_SITES = [
  { id: 'site-1-id', name: 'Production Site' },
  { id: 'site-2-id', name: 'Staging Site' },
  { id: 'site-3-id', name: 'Documentation' }
]

add_pane do |pane|
  pane.height = 1.0; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "All Sites Status"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    
    content.add_row("=== Site Status Overview ===")
    
    NETLIFY_SITES.each do |site_config|
      begin
        site = netlify.get("/sites/#{site_config[:id]}")
        
        # Get latest deployment
        deployments = netlify.get("/sites/#{site_config[:id]}/deploys", { per_page: 1 })
        latest_deploy = deployments.first
        
        status_color = case latest_deploy['state']
        when 'ready' then 'green'
        when 'building' then 'yellow'
        when 'error' then 'red'
        else 'white'
        end
        
        content.add_row("[fg=#{status_color}]#{site_config[:name]}: #{latest_deploy['state']}", {
          site: site,
          deployment: latest_deploy,
          config: site_config
        })
        
        if latest_deploy['published_at']
          published_time = Time.parse(latest_deploy['published_at'])
          time_ago = ((Time.now - published_time) / 3600).round(1)
          content.add_row("  Last deployed: #{time_ago}h ago")
        end
        
      rescue => e
        content.add_row("[fg=red]#{site_config[:name]}: Error - #{e.message}")
      end
    end
  end
  
  pane.selection do |data|
    if data[:site]
      system("open #{data[:site]['admin_url']}")
    end
  end
end
```

### Build Status Monitor

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.5; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Build Status"
  pane.interval = 60

  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    site_id = ENV['WASSUP_NETLIFY_SITE_ID']
    
    begin
      # Get recent deployments
      deployments = netlify.get("/sites/#{site_id}/deploys", { per_page: 5 })
      
      content.add_row("=== Recent Deployments ===")
      
      deployments.each do |deploy|
        case deploy['state']
        when 'ready'
          status = "[fg=green]✓ Ready"
        when 'building'
          status = "[fg=yellow]⏳ Building"
        when 'error'
          status = "[fg=red]✗ Failed"
        when 'processing'
          status = "[fg=blue]🔄 Processing"
        else
          status = "[fg=white]● #{deploy['state']}"
        end
        
        branch = deploy['branch'] || 'unknown'
        commit = deploy['commit_ref'] ? deploy['commit_ref'][0..7] : 'no-commit'
        
        content.add_row("#{status} #{branch} (#{commit})", deploy)
        
        if deploy['published_at']
          published_time = Time.parse(deploy['published_at'])
          content.add_row("  #{published_time.strftime('%m/%d %H:%M')}")
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |deploy|
    system("open #{deploy['admin_url']}")
  end
end
```

### Form Submissions

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.5; pane.width = 1.0; pane.top = 0.5; pane.left = 0
  pane.title = "Form Submissions"
  pane.highlight = true
  pane.interval = 60 * 10

  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    site_id = ENV['WASSUP_NETLIFY_SITE_ID']
    
    begin
      # Get forms for the site
      forms = netlify.get("/sites/#{site_id}/forms")
      
      if forms.empty?
        content.add_row("No forms found for this site")
      else
        content.add_row("=== Form Submissions ===")
        
        forms.each do |form|
          # Get recent submissions
          submissions = netlify.get("/forms/#{form['id']}/submissions", { per_page: 5 })
          
          content.add_row("#{form['name']}: #{submissions.length} recent submissions", {
            form: form,
            submissions: submissions
          })
          
          submissions.each do |submission|
            created_at = Time.parse(submission['created_at'])
            time_ago = ((Time.now - created_at) / 3600).round(1)
            content.add_row("  #{time_ago}h ago from #{submission['ip']}")
          end
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |data|
    if data[:form]
      system("open https://app.netlify.com/sites/#{site_id}/forms/#{data[:form]['id']}")
    end
  end
end
```

## Advanced Configuration

### Site Analytics

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.4; pane.width = 1.0; pane.top = 0; pane.left = 0
  pane.title = "Site Analytics"
  pane.interval = 60 * 15

  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    site_id = ENV['WASSUP_NETLIFY_SITE_ID']
    
    begin
      # Get site info
      site = netlify.get("/sites/#{site_id}")
      
      # Get analytics (if available)
      analytics = netlify.get("/sites/#{site_id}/analytics/pageviews")
      
      content.add_row("=== Site Analytics ===")
      content.add_row("Site: #{site['name']}")
      content.add_row("URL: #{site['url']}")
      content.add_row("Custom Domain: #{site['custom_domain'] || 'None'}")
      
      if analytics && analytics['data']
        total_views = analytics['data'].sum { |day| day['views'] }
        content.add_row("Total Page Views: #{total_views}")
        
        # Show recent daily views
        content.add_row("")
        content.add_row("Recent Daily Views:")
        analytics['data'].last(7).each do |day|
          content.add_row("  #{day['date']}: #{day['views']} views")
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
end
```

### Build Logs Monitor

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.6; pane.width = 1.0; pane.top = 0.4; pane.left = 0
  pane.title = "Build Logs"
  pane.highlight = true
  pane.interval = 60 * 5

  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    site_id = ENV['WASSUP_NETLIFY_SITE_ID']
    
    begin
      # Get the latest deployment
      deployments = netlify.get("/sites/#{site_id}/deploys", { per_page: 1 })
      
      if deployments.empty?
        content.add_row("No deployments found")
      else
        latest_deploy = deployments.first
        
        content.add_row("=== Latest Build Log ===")
        content.add_row("Deploy ID: #{latest_deploy['id']}")
        content.add_row("State: #{latest_deploy['state']}")
        content.add_row("Branch: #{latest_deploy['branch']}")
        
        # Get build log
        begin
          log = netlify.get("/deploys/#{latest_deploy['id']}/log")
          
          if log && log['log']
            content.add_row("")
            content.add_row("Build Log:")
            
            # Show last 20 lines of log
            log_lines = log['log'].split("\n")
            log_lines.last(20).each do |line|
              # Color code log levels
              if line.include?('ERROR') || line.include?('error')
                content.add_row("[fg=red]#{line}")
              elsif line.include?('WARN') || line.include?('warning')
                content.add_row("[fg=yellow]#{line}")
              elsif line.include?('INFO') || line.include?('info')
                content.add_row("[fg=blue]#{line}")
              else
                content.add_row(line)
              end
            end
          else
            content.add_row("No build log available")
          end
          
        rescue => log_error
          content.add_row("[fg=red]Could not fetch build log: #{log_error.message}")
        end
      end
      
    rescue => e
      content.add_row("[fg=red]Error: #{e.message}")
    end
  end
  
  pane.selection do |data|
    if data && data['admin_url']
      system("open #{data['admin_url']}")
    end
  end
end
```

## Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `WASSUP_NETLIFY_ACCESS_TOKEN` | Your Netlify personal access token | Yes |
| `WASSUP_NETLIFY_SITE_ID` | Default site ID for single-site monitoring | No |

## Rate Limiting

Netlify API has rate limits:
- **500 requests per minute** per access token
- **100 requests per minute** per IP address

Wassup automatically handles rate limiting with intelligent queuing.

## Troubleshooting

### Common Issues

**Token Authentication Errors**
```bash
# Verify token is valid
curl -H "Authorization: Bearer $WASSUP_NETLIFY_ACCESS_TOKEN" \
  https://api.netlify.com/api/v1/user
```

**Site Access Issues**
```bash
# Check if site ID is correct
curl -H "Authorization: Bearer $WASSUP_NETLIFY_ACCESS_TOKEN" \
  https://api.netlify.com/api/v1/sites | jq '.[] | {id: .id, name: .name}'
```

**Build Log Access**
- Build logs may not be available immediately
- Logs are only retained for a limited time
- Some deployment states don't have logs

### Debug Mode

```ruby title="Supfile"
# Enable debug logging for Netlify API calls
add_pane do |pane|
  pane.title = "Netlify Debug"
  pane.content do |content|
    netlify = Wassup::Helpers::Netlify.new
    netlify.debug = true  # Enable debug mode
    
    begin
      sites = netlify.get("/sites")
      content.add_row("Found #{sites.length} sites")
    rescue => e
      content.add_row("[fg=red]Debug error: #{e.message}")
    end
  end
end
```

## Best Practices

1. **Use specific site IDs** - More efficient than querying all sites
2. **Set appropriate intervals** - Deployments don't change frequently
3. **Monitor critical metrics** - Focus on build status and errors
4. **Handle rate limits** - Use reasonable refresh intervals
5. **Cache expensive calls** - Store site information locally when possible

## Next Steps

- [GitHub Integration](../github/setup.md) - Monitor your repository alongside deployments
- [API Helpers](../../helpers/api-helpers.md) - Custom API integration patterns
- [Troubleshooting](../../troubleshooting/common-issues.md) - Common integration issues