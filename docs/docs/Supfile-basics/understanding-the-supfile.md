---
sidebar_position: 1
---

# Understanding the `Supfile`

The `Supfile` is what **Wassup** uses to generate the dashboard.

The dashboard is made up of **panes**. These **panes** are configured by the `Supfile`.

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.4
  pane.top = 0
  pane.left = 0

  pane.title = "Current Time"

  pane.highlight = false

  pane.interval = 1
  pane.content do |content|
    date = `date`
    content.add_row(date)
  end
end
```

## Properties

### Positioning

| Property | Type | Description |
| --- | --- | --- |
| height | Float | Height of the pane (value between 0 and 1) |
| width | Float | Width of the pane (value between 0 and 1) |
| top | Float | Top positioning of the pane (value between 0 and 1) |
| left | Float | Left positioning of the pane (value between 0 and 1) |
| title | String | Title to display in the top border of the pane |

### Content

| Property | Type | Description |
| --- | --- | --- |
| interval | Integer (or Float) | Interval (in seconds) on how often to refresh pane with the `content` block |
| show_refresh | Boolean | Whether or not to show when a content refresh is happening |
| highlight | Boolean | Whether or not to allow highlighting and selection of rows |
| content | Block | A Ruby block for fetching and adding content to the pane |
| selection | Block | A Ruby block for fetching and adding content to the pane |