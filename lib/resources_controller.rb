require 'ardes/resources_controller'
require 'ardes/active_record/saved'

module Ardes
  module ResourcesController
    class Railtie < Rails::Railtie
      initializer 'ardes.resources_controller' do
        ActiveSupport.on_load(:action_controller) do
          extend Ardes::ResourcesController
          include Ardes::ResourcesController::RequestPathIntrospection
        end
        
        ActiveSupport.on_load(:active_record) do
          include Ardes::ActiveRecord::Saved
        end
      end
    end
  end
end