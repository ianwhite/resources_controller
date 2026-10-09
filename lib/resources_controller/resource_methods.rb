module ResourcesController
  # methods which communicate with the resource_service to find/create resources
  module ResourceMethods
  protected
    # finds the collection of resources
    def find_resources
      resource_service.all
    end

    # finds the resource, using the passed id, defaults to the current params[:id]
    def find_resource(id = nil)
      id ||= respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[:id]
      resource_service.find id
    end

    # makes a new resource, if attributes are not supplied, determine them from the
    # params hash and the current resource_class, or resource_name (the latter left in for BC)
    def new_resource(attributes = nil, &block)
      if attributes.blank? && respond_to?(:params) && params.is_a?(ActionController::Parameters)
        resource_form_name = ActiveModel::Naming.singular(resource_class)
        attributes = params[resource_form_name] || params[resource_name] || {}
      end
      resource_service.new attributes, &block
    end
    
    # destroys and returns the resource, using the passed id, defaults to the current params[:id]
    def destroy_resource(id = nil)
      id ||= respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[:id]
      resource_service.destroy id
    end


    EXCLUDED_PARAM_COLUMNS = %w[updated_at created_at].freeze

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      method_name = "#{resource_name}_params"
      if respond_to?(method_name, true)
        send(method_name)
      else
        columns = resource_service.content_columns.map(&:name) - EXCLUDED_PARAM_COLUMNS
        params.fetch(resource_name) { {} }.permit(*columns)
      end
    end
  
  end
end
