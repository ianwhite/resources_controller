module Ardes
  module ResourcesController
    module RequestPathIntrospection
    
    protected
      def request_path
        @request_path ||= params[:resource_path] || request.path
      end
      
      def nesting_request_path
        @nesting_request_path ||= remove_namespace(request_path.sub(%r(/#{current_segment}(?!.*/#{current_segment}).*$), ''))
      end
      
      # returns an array of hashes like {:segment => 'forum', :singleton => false}
      def nesting_segments
        segments_for_path_and_keys(nesting_request_path, params.keys.select{|k| k.to_s[-3..-1] == '_id'})
      end
      
    private
      def current_segment
        respond_to?(:resource_specification) ? resource_specification.segment : controller_name
      end
        
      def remove_namespace(path)
        (controller_path != controller_name) ? path.sub(%r(^/#{controller_path.sub(%r(/#{controller_name}), '')}), '') : path
      end
    
      def segments_for_path_and_keys(path, keys)
        key_segments = keys.map{|k| segment_for_key(k)}
        path_segments = path[1..-1].split('/')
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