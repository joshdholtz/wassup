require_relative 'lib/wassup/version'

Gem::Specification.new do |spec|
  spec.name          = "wassup"
  spec.version       = Wassup::VERSION
  spec.authors       = ["Josh Holtz"]
  spec.email         = ["me@joshholtz.com"]

  spec.summary       = %q{A scriptable terminal dashboard}
  spec.description   = %q{A scriptable terminal dashboard}
  spec.homepage      = "https://github.com/joshdholtz/wassup"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/joshdholtz/wassup"

  spec.add_runtime_dependency 'curses'
  spec.add_runtime_dependency 'rest-client'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["wassup"]
  spec.require_paths = ["lib"]
end
