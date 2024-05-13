# frozen_string_literal: true

require_relative 'lib/shale/builder/version'

Gem::Specification.new do |spec|
  spec.name = 'shale-builder'
  spec.version = Shale::Builder::VERSION
  spec.authors = ['Mateusz Drewniak']
  spec.email = ['matmg24@gmail.com']

  spec.summary = 'An addon to the shale Ruby gem which adds a simple yet powerful builder DSL.'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/Verseth/ruby-shale-builder'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/Verseth/ruby-shale-builder/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.match(%r{\A(?:(?:bin|test|spec|features|sorbet)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'booleans', '>= 0.1'
  spec.add_dependency 'shale', '< 2.0'
  spec.add_dependency 'sorbet-runtime', '> 0.5'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
