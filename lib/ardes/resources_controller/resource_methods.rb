module Ardes
  module ResourcesController
    # methods which communicate with the resource_service to find/create resources
    module ResourceMethods
    protected
      # finds the collection of resources
      def find_resources
        resource_service.find :all
      end

      # finds the resource, using the passed id, defaults to the current params[:id]
      def find_resource(id = nil)
        id ||= respond_to?(:params) && params.is_a?(Hash) && params[:id]
        resource_service.find id
      end

      # makes a new resource, if attributes are not supplied, determine them from the
      # params hash and the current resource_class, or resource_name (the latter left in for BC)
      def new_resource(attributes = nil, &block)
        if attributes.blank? && respond_to?(:params) && params.is_a?(Hash)
          resource_form_name = ActionController::RecordIdentifier.singular_class_name(resource_class)
          attributes = params[resource_form_name] || params[resource_name] || {}
        end
        resource_service.new attributes, &block
      end
      
      # destroys and returns the resource, using the passed id, defaults to the current params[:id]
      def destroy_resource(id = nil)
        id ||= respond_to?(:params) && params.is_a?(Hash) && params[:id]
        resource_service.destroy id
      end
    end
  end
end