# frozen_string_literal: true

source 'https://rubygems.org'

rails_version = ENV.fetch('RAILS_VERSION', '7.1')
gem 'actionpack', "~> #{rails_version}.0"
gem 'activesupport', "~> #{rails_version}.0"

gemspec

group :development, :test do
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.80', require: false
  gem 'simplecov', require: false
end
