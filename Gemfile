# frozen_string_literal: true

source 'https://rubygems.org'

rails_version = ENV.fetch('RAILS_VERSION', '7.1')
gem 'actionpack', "~> #{rails_version}.0"
gem 'activesupport', "~> #{rails_version}.0"

gemspec

group :development, :test do
  gem 'rspec', '~> 3.12'
  gem 'rubocop', '~> 1.60', require: false
end
