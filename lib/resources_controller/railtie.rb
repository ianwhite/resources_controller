module ResourcesController
  class Railtie < Rails::Railtie
    initializer 'resources_controller' do
      ActiveSupport.on_load(:action_controller) do
        extend ResourcesController
        include ResourcesController::RequestPathIntrospection
      end
      
      ActiveSupport.on_load(:active_record) do
        include ResourcesController::ActiveRecord::Saved
      end
    end
  end
end