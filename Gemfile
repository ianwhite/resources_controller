source "https://rubygems.org"

gemspec

# CI exercises the oldest and the newest supported Rails releases by setting
# RAILS_VERSION, e.g. RAILS_VERSION='~> 8.0.0' bundle install && bundle exec rspec
rails_version = ENV["RAILS_VERSION"].to_s
gem "rails", rails_version unless rails_version.empty?
