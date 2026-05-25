# frozen_string_literal: true

source 'https://rubygems.org'

rails_version = ENV.fetch('RAILS_VERSION', '7.1')
gem 'actionpack', "~> #{rails_version}.0"
gem 'activesupport', "~> #{rails_version}.0"
gem 'railties', "~> #{rails_version}.0"

gemspec

group :development, :test do
  gem 'phlex', '~> 2.0', require: false
  gem 'rexml'
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.80', require: false
  gem 'simplecov', require: false
  gem 'view_component', '>= 4.9', '< 5', require: false
end
