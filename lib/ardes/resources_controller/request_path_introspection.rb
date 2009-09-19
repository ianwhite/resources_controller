module Ardes
  module ResourcesController
    module RequestPathIntrospection
    
    protected
      def request_path
        @request_path ||= params[:resource_path] || request.path
      end
      
      def nesting_request_path
        @nesting_request_path ||= remove_namespace(request_path.sub(%r(/#{resource_segment}(?!.*/#{resource_segment}).*$), ''))
      end
      
    private
      def resource_segment
        respond_to?(:resource_specification) ? resource_specification.segment : controller_name
      end
        
      def remove_namespace(path)
        (controller_path != controller_name) ? path.sub(%r(^/#{controller_path.sub(%r(/#{controller_name}), '')}), '') : path
      end
    end
  end
end