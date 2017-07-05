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

    # makes a new resource.  If attributes are not supplied, we try to get them
    # from 'resource_params', if available.
    def new_resource(attributes = nil, &block)
      if attributes.blank? && respond_to?(:resource_params)
        attributes = resource_params
      end
      resource_service.new attributes, &block
    end
    
    # destroys and returns the resource, using the passed id, defaults to the current params[:id]
    def destroy_resource(id = nil)
      id ||= respond_to?(:params) && params.is_a?(ActionController::Parameters) && params[:id]
      resource_service.destroy id
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      if defined?(super)
        return super
      elsif self.respond_to?("#{resource_name}_params", true)
        return self.send("#{resource_name}_params")
      else
        raise NoMethodError, "resource_params and #{resource_name}_params both unimplemented"
      end
    end
  
  end
end
