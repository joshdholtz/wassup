require "wassup/version"
require "wassup/app"
require "wassup/color"
require "wassup/pane"
require "wassup/pane_builder"

require "wassup/helpers/circleci"
require "wassup/helpers/github"
require "wassup/helpers/netlify"
require "wassup/helpers/shortcut"

require "wassup/panes/circleci"
require "wassup/panes/github"
require "wassup/panes/netlify"
require "wassup/panes/shortcut"
require "wassup/panes/world_clock"

module Wassup
  class Error < StandardError; end
  # Your code goes here...
end
