module Ardes
  module ResourcesController
    # included into ActionController::Base
    #
    # provides ability to determine what nesting segments are for a given request, and whether those segments are singletons,
    # these methods are aware of resource specifications specified either by map_enclosing_resource.
    module RequestPathIntrospection
    protected
      def request_path
        @request_path ||= params[:resource_path] || request.path
      end
      
      def nesting_request_path
        @nesting_request_path ||= remove_namespace(remove_current_segment(request_path))
      end
      
      # returns an array of hashes like {:segment => 'forum', :singleton => false}
      def nesting_segments
        @nesting_segments ||= segments_for_path_and_keys(nesting_request_path, param_keys)
      end
      
      # returns an array of segments correspopnding to the namespace of the controller.
      # If your controller is at a non standard location wrt it's path, you can modify this array in a before filter
      # to help resources_controller do the right thing
      def namespace_segments
        unless @namespace_segments
          namespace = controller_path.sub(%r(#{controller_name}$), '')
          @namespace_segments = (request_path =~ %r(^/#{namespace}) ? namespace.split('/') : [])
        end
        @namespace_segments
      end
      
      def param_keys
        params.keys.map(&:to_s).select{|k| k[-3..-1] == '_id'}
      end
      
    private
      def remove_current_segment(path)
        if respond_to?(:resource_specification) && resource_specification.singleton?
          path.sub(%r(/#{current_segment}(?!.*/#{current_segment}).*$), '')
        else
          path.sub(%r(/#{current_segment}(?!.+/#{current_segment}).*$), '')
        end
      end
      
      def current_segment
        respond_to?(:resource_specification) ? resource_specification.segment : controller_name
      end
        
      def remove_namespace(path)
        if namespace_segments.any?
          path.sub(%r(^/#{namespace_segments.join('/')}), '')
        else
          path
        end
      end
      
      def segments_for_path_and_keys(path, keys)
        key_segments = keys.map{|k| segment_for_key(k)}
        path_segments = path[1..-1].to_s.split('/')
        segments = []
        while path_segments.any? do
          segment = path_segments.shift
          if key_segments.include?(segment)
            segments << {:segment => segment, :singleton => false}
            path_segments.shift # swallow following :id
          else
            segments << {:segment => segment, :singleton => true}
          end
        end
        segments
      end
      
      def segment_for_key(key)
        if respond_to?(:specifications) && spec = specifications.find{|s| s.respond_to?(:key) && s.key == key.to_s}
          spec.segment
        elsif spec = resource_specification_map.values.find{|s| s.key == key.to_s}
          spec.segment
        else
          key.to_s[0..-4].pluralize
        end
      end
    end
  end
end