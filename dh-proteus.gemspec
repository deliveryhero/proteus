
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "proteus/version"

Gem::Specification.new do |spec|
  spec.name          = "dh-proteus"
  spec.version       = Proteus::VERSION
  spec.authors       = ["Simon Albrecht"]
  spec.email         = ["simon.albrecht@deliveryhero.com"]

  spec.summary       = %q{Proteus is a Terraform wrapper application.}
  #spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/deliveryhero/proteus"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/deliveryhero/proteus"
    spec.metadata["changelog_uri"] = "https://github.com/deliveryhero/proteus/CHANGELOG"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ['proteus']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"

  spec.add_runtime_dependency 'activesupport', '~> 5.1.1'
  spec.add_runtime_dependency 'thor', '~> 0.20.0'
  spec.add_runtime_dependency 'erubis', '~> 2.7.0'
end
