require 'ardes/active_record/saved'
ActiveRecord::Base.send :include, Ardes::ActiveRecord::Saved

require 'ardes/resources_controller'
ActionController::Base.extend Ardes::ResourcesController
