# World Clock Pane

The World Clock pane allows you to display multiple time zones in your Wassup dashboard. Perfect for distributed teams, it shows current times across different locations with optional color coding for working hours.

## Features

- **Multiple timezone support** - Display any number of locations
- **Working hours color coding** - Visual indicators for collaboration timing
- **Flexible configuration** - Customizable time/date formats and working hours
- **Smart timezone handling** - Uses system TZ support with DST awareness
- **Sorting options** - alphabetical, chronological, reverse chronological, natural

## Basic Configuration

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "World Clock"
  pane.interval = 60  # Update every minute
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "New York" => "America/New_York",
      "London" => "Europe/London",
      "Tokyo" => "Asia/Tokyo"
    }
  )
end
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `locations` | Hash | `{}` | Map of display names to timezone identifiers |
| `sort_order` | String | `"natural"` | Sort order: "alphabetical", "chronological", "reversechronological", "natural" |
| `time_format` | String | `"%H:%M:%S"` | Time display format (Ruby strftime) |
| `date_format` | String | `"%Y-%m-%d"` | Date display format (Ruby strftime) |
| `working_hours` | Hash | `{start: 9, end: 17}` | Working hours definition |
| `color_coding` | Boolean | `true` | Enable/disable working hours color coding |

## Timezone Formats

The World Clock pane supports multiple timezone formats:

### TZ Database Names (Recommended)

```ruby
locations: {
  "New York" => "America/New_York",
  "Los Angeles" => "America/Los_Angeles",
  "Chicago" => "America/Chicago",
  "London" => "Europe/London",
  "Paris" => "Europe/Paris",
  "Berlin" => "Europe/Berlin",
  "Madrid" => "Europe/Madrid",
  "Warsaw" => "Europe/Warsaw",
  "Tokyo" => "Asia/Tokyo",
  "Dubai" => "Asia/Dubai",
  "Sydney" => "Australia/Sydney",
  "Montevideo" => "America/Montevideo"
}
```

### UTC Offsets

```ruby
locations: {
  "UTC" => "UTC",
  "GMT+1" => "+01:00",
  "GMT-5" => "-05:00",
  "Singapore" => "+08:00"
}
```

## Working Hours Color Coding

The World Clock pane can color-code times based on working hours:

- 🟢 **Green** - Core working hours
- 🟡 **Yellow** - Transition hours (1 hour before/after work)
- 🔴 **Red** - Outside working hours

### Color Coding Configuration

```ruby
pane.type = Wassup::Panes::WorldClock.new(
  locations: {
    "Me" => "America/Chicago",
    "Dan" => "America/New_York",
    "Franco" => "America/Montevideo",
    "Barbara" => "Europe/Madrid",
    "Marek" => "Europe/Warsaw"
  },
  working_hours: {start: 9, end: 17},  # 9 AM to 5 PM
  color_coding: true
)
```

### Custom Working Hours

```ruby
# Early bird schedule
working_hours: {start: 7, end: 15}  # 7 AM to 3 PM

# Standard business hours
working_hours: {start: 9, end: 17}  # 9 AM to 5 PM

# Extended hours
working_hours: {start: 8, end: 18}  # 8 AM to 6 PM

# Evening shift
working_hours: {start: 14, end: 22}  # 2 PM to 10 PM
```

## Sorting Options

### Alphabetical

Sort locations alphabetically by name:

```ruby
sort_order: "alphabetical"
```

### Chronological

Sort by current time (earliest to latest):

```ruby
sort_order: "chronological"
```

### Reverse Chronological

Sort by current time (latest to earliest):

```ruby
sort_order: "reversechronological"
```

### Natural

Keep the original order specified in the configuration:

```ruby
sort_order: "natural"
```

## Time and Date Formatting

### Common Time Formats

```ruby
# 24-hour format
time_format: "%H:%M:%S"    # 14:30:45
time_format: "%H:%M"       # 14:30

# 12-hour format
time_format: "%I:%M %p"    # 02:30 PM
time_format: "%I:%M%p"     # 02:30PM
time_format: "%l:%M %p"    # 2:30 PM (no leading zero)
```

### Common Date Formats

```ruby
# ISO format
date_format: "%Y-%m-%d"    # 2023-12-25

# US format
date_format: "%m/%d/%Y"    # 12/25/2023

# Abbreviated with day
date_format: "%a %b %d"    # Mon Dec 25

# Full date
date_format: "%A, %B %d, %Y"  # Monday, December 25, 2023
```

## Example Configurations

### Team Coordination Dashboard

```ruby
add_pane do |pane|
  pane.height = 0.6
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Team Time Zones"
  pane.interval = 60
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "Josh (Chicago)" => "America/Chicago",
      "Dan (New York)" => "America/New_York",
      "Franco (Montevideo)" => "America/Montevideo",
      "Barbara (Madrid)" => "Europe/Madrid",
      "Marek (Warsaw)" => "Europe/Warsaw"
    },
    sort_order: "chronological",
    time_format: "%I:%M%p",
    date_format: "%a %b %d",
    working_hours: {start: 9, end: 17},
    color_coding: true
  )
end
```

### Global Office Hours

```ruby
add_pane do |pane|
  pane.height = 0.4
  pane.width = 0.5
  pane.top = 0
  pane.left = 0
  
  pane.title = "Office Hours"
  pane.interval = 300  # Update every 5 minutes
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "San Francisco" => "America/Los_Angeles",
      "New York" => "America/New_York",
      "London" => "Europe/London",
      "Singapore" => "+08:00"
    },
    sort_order: "alphabetical",
    time_format: "%H:%M",
    date_format: "%a",
    working_hours: {start: 8, end: 18},
    color_coding: true
  )
end
```

### Meeting Scheduler

```ruby
add_pane do |pane|
  pane.height = 0.5
  pane.width = 1.0
  pane.top = 0.5
  pane.left = 0
  
  pane.title = "Meeting Times"
  pane.interval = 60
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "West Coast" => "America/Los_Angeles",
      "East Coast" => "America/New_York",
      "London" => "Europe/London",
      "Central Europe" => "Europe/Berlin",
      "India" => "Asia/Kolkata",
      "Australia" => "Australia/Sydney"
    },
    sort_order: "chronological",
    time_format: "%I:%M %p",
    date_format: "%a %b %d",
    working_hours: {start: 9, end: 17},
    color_coding: true
  )
end
```

## Advanced Features

### Daylight Saving Time (DST)

The World Clock pane automatically handles DST transitions for supported timezones:

- **US/Canada** - Second Sunday in March to first Sunday in November
- **Europe** - Last Sunday in March to last Sunday in October  
- **Australia** - First Sunday in October to first Sunday in April

### Multiple Panes for Different Contexts

```ruby
# Personal contacts
add_pane do |pane|
  pane.height = 0.33
  pane.width = 1.0
  pane.top = 0
  pane.left = 0
  
  pane.title = "Family & Friends"
  pane.interval = 300
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "Mom (Phoenix)" => "America/Phoenix",
      "Sister (London)" => "Europe/London",
      "Friend (Tokyo)" => "Asia/Tokyo"
    },
    sort_order: "alphabetical",
    working_hours: {start: 8, end: 22},  # Extended hours for personal
    color_coding: true
  )
end

# Work contacts
add_pane do |pane|
  pane.height = 0.33
  pane.width = 1.0
  pane.top = 0.33
  pane.left = 0
  
  pane.title = "Work Team"
  pane.interval = 180
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "Office (SF)" => "America/Los_Angeles",
      "Remote (NYC)" => "America/New_York",
      "Remote (Berlin)" => "Europe/Berlin"
    },
    sort_order: "chronological",
    working_hours: {start: 9, end: 17},
    color_coding: true
  )
end

# Client locations
add_pane do |pane|
  pane.height = 0.34
  pane.width = 1.0
  pane.top = 0.66
  pane.left = 0
  
  pane.title = "Client Locations"
  pane.interval = 600
  
  pane.type = Wassup::Panes::WorldClock.new(
    locations: {
      "Client A (Dubai)" => "Asia/Dubai",
      "Client B (Sydney)" => "Australia/Sydney",
      "Client C (São Paulo)" => "America/Sao_Paulo"
    },
    sort_order: "alphabetical",
    working_hours: {start: 8, end: 18},
    color_coding: true
  )
end
```

## Best Practices

### Refresh Intervals

- **60 seconds** - For active coordination (recommended)
- **300 seconds** - For general awareness
- **600 seconds** - For reference information

### Location Naming

Use descriptive names that provide context:

```ruby
# Good - includes person/role context
"Josh (Product)" => "America/Chicago"
"Remote Dev Team" => "Europe/London"
"Client (APAC)" => "Asia/Singapore"

# Less helpful - generic names
"Chicago" => "America/Chicago"
"London" => "Europe/London"
"Singapore" => "Asia/Singapore"
```

### Working Hours Configuration

Consider different working hour patterns for different contexts:

```ruby
# Standard business hours
working_hours: {start: 9, end: 17}

# Development team (may work later)
working_hours: {start: 10, end: 18}

# Customer support (extended hours)
working_hours: {start: 7, end: 19}

# Personal contacts (more flexible)
working_hours: {start: 8, end: 22}
```

## Troubleshooting

### Timezone Issues

If times appear incorrect:

1. Verify timezone identifiers are correct
2. Check if DST is being handled properly
3. Ensure system timezone data is up to date

### Performance

For better performance:

- Use longer intervals for less critical information
- Limit the number of locations to avoid clutter
- Consider splitting into multiple panes for different contexts

### Display Issues

If the display looks wrong:

- Check terminal size and pane dimensions
- Verify time/date format strings are valid
- Ensure location names aren't too long for the display

For more troubleshooting help, see the [Common Issues Guide](../troubleshooting/common-issues.md).