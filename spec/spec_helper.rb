ENV["RAILS_ENV"] ||= "test"

# this jiggery pokery is because edge rails currently borks unless
# you load config/environment from RAILS_ROOT - see #1557
require 'fileutils'
include FileUtils
cd File.join(File.dirname(__FILE__), "../../../..") do
  require "config/environment"
end

require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
end