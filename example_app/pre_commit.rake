# require the pre_commit/rake file
require File.dirname(__FILE__) + '/../pre_commit/lib/pre_commit'
require File.dirname(__FILE__) + '/../resources_controller/pre_commit'
require 'pre_commit/rake_tasks'

ENV['RAILS_ENV'] = 'test'

PreCommit::ResourcesController.new(self)
