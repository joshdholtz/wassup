<h3 align="center">
  <img height="200" alt="Wassup logo" src="https://user-images.githubusercontent.com/401294/145626927-7eb0fda5-c62a-47c8-9422-074b178fd8ef.png" />
</h3>

[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/fastlane/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/wassup.svg?style=flat)](https://rubygems.org/gems/wassup)

**Wassup** is a scriptable terminal dashboard. Configure panes and content logic in a `Supfile` and then run `wassup`.

<hr/>

https://user-images.githubusercontent.com/401294/145632767-d75a8244-b68f-4838-8ff4-4017ba0c1ed2.mov

## Example `Supfile`

```rb
require 'json'
require 'rest-client'

add_pane do |pane|
  pane.height = 0.5
  pane.width = 0.5
  pane.top = 0
  pane.left = 0

  pane.highlight = true
  pane.title = "Open PRs - fastlane/fastlane"

  pane.interval = 60 * 5
  pane.content do |builder|
    resp = RestClient.get "https://api.github.com/repos/fastlane/fastlane/pulls"
    json = JSON.parse(resp)
    json.map do |pr|
      display = "##{pr["number"]} #{pr["title"]}"

      # First argument is displayed
      # Second argument is passed to pane.selection
      builder.add_row(display, pr["html_url"])
    end
  end
  pane.selection do |url|
    `open #{url}`
  end
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wassup'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wassup

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wassup. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/wassup/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Wassup project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wassup/blob/master/CODE_OF_CONDUCT.md).
