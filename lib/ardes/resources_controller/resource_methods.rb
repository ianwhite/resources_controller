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
        id ||= respond_to?(:params) && params[:id]
        resource_service.find id
      end

      # makes a new resource, if attributes are not supplied, determine them from the
      # params hash and the current resource_name
      #
      # resource_service transforms a #new message into #build for associations, or #new for classes
      def new_resource(attributes = nil, &block)
        attributes ||= (respond_to?(:params) && params[resource_name]) || {}
        resource_service.new attributes, &block
      end
    end
  end
end