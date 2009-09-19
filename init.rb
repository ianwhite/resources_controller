require 'ardes/resources_controller'
ActionController::Base.extend Ardes::ResourcesController
ActionController::Base.send :include, Ardes::ResourcesController::RequestPathIntrospection

require 'ardes/active_record/saved'
ActiveRecord::Base.send :include, Ardes::ActiveRecord::Saved