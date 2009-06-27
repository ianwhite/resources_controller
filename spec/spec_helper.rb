ENV["RAILS_ENV"] ||= "test"
require File.join(File.dirname(__FILE__), "../../../../config/environment")
require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
end

# BC: fix for ruby 1.8.7 + rails 2.0.x Enumerable problem
unless String.new.respond_to?(:force_encoding)
  String.send(:remove_method, :chars) rescue nil
end