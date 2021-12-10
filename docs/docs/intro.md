---
sidebar_position: 1
---

# Getting Started

Get started by **installing the gem**.

## Installing

Install **Wassup** from RubyGems:

```shell
gem install wassup
```

Or in a `Gemfile`:

```rb
source "https://rubygems.org"

gem "wassup"
```

## Create Your First `Supfile`

Create a `Supfile` with the following contents:

```ruby title="Supfile"
add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.4
  pane.top = 0
  pane.left = 0

  pane.highlight = false
  pane.title = "Current Time"

  pane.interval = 1
  pane.content do |content|
    date = `date`

    content.add_row(date)
  end
end
```

Run `wassup` (or `bundle exec wassup` if using a `Gemfile`) from your terminal in the same directory as your `Supfile`.

### Screenshot

You should see a pane in the top left corner that updates the time every second.

![Tutorial intro starter screenshot](/img/tutorial-intro-starter-screenshot.png)
