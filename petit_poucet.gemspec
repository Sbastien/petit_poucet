# frozen_string_literal: true

require_relative 'lib/petit_poucet/version'

Gem::Specification.new do |spec|
  spec.name          = 'petit_poucet'
  spec.version       = PetitPoucet::VERSION
  spec.authors       = ['TeepTrak']
  spec.email         = ['dev@teeptrak.com']

  spec.summary       = 'Modern breadcrumbs DSL for Rails'
  spec.description   = 'Minimal breadcrumbs gem with declarative DSL and action filtering'
  spec.homepage      = 'https://github.com/TEEPTRAK-TEAM/petit_poucet'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'actionpack', '>= 7.0'
  spec.add_dependency 'activesupport', '>= 7.0'
end
