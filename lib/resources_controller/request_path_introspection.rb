# frozen_string_literal: true

module ResourcesController
  # included into ActionController::Base
  #
  # provides ability to determine what nesting segments are for a given request, and whether those segments are singletons,
  # these methods are aware of resource specifications specified either by map_enclosing_resource.
  module RequestPathIntrospection
  protected
    # NOTE: this is deliberately not called #request_path.  A route like
    # `resources :requests` generates a named route helper called request_path, and the
    # url_helpers module is included into the controller after this one, so it wins the
    # name lookup - resources_controller would then read the helper's value instead of
    # the path of the current request.  See spec/lib/request_path_introspection_spec.rb.
    def rc_request_path
      @rc_request_path ||= request.path_parameters[:resource_path] || request.path
    end
    
    def nesting_request_path
      @nesting_request_path ||= remove_namespace(remove_current_segment(rc_request_path))
    end
    
    # returns an array of hashes like {:segment => 'forum', :singleton => false}
    def nesting_segments
      @nesting_segments ||= begin
        path = nesting_request_path
        path.empty? || path == '/' ? [] : segments_for_path_and_keys(path, param_keys)
      end
    end
    
    # returns an array of segments correspopnding to the namespace of the controller.
    # If your controller is at a non standard location wrt it's path, you can modify this array in a before filter
    # to help resources_controller do the right thing
    def namespace_segments
      @namespace_segments ||= begin
        path = controller_path
        name = controller_name
        if path == name
          []
        else
          namespace = path.delete_suffix(name).delete_suffix('/')
          if namespace.empty? || !rc_request_path.start_with?("/#{namespace}")
            []
          else
            namespace.split('/')
          end
        end
      end
    end
    
    def param_keys
      keys = []
      params.each_key do |k|
        k_str = k.to_s
        keys << k_str if k_str.end_with?('_id')
      end
      keys
    end
    
  private
    # Removes the current resource segment, and everything after it, from the path,
    # e.g. '/users/1/forums/2' => '/users/1'.
    #
    # This is only called from #nesting_request_path, which is memoised per request,
    # so the pattern is built at most once per request - there is no need to cache it.
    # The segment is escaped so that it is matched literally, as in #remove_namespace.
    def remove_current_segment(path)
      segment = Regexp.escape(current_segment.to_s)
      pattern = if respond_to?(:resource_specification) && resource_specification.singleton?
        %r(/#{segment}(?!.*/#{segment}).*$)
      else
        %r(/#{segment}(?!.+/#{segment}).*$)
      end
      path.sub(pattern, '')
    end
    
    def current_segment
      respond_to?(:resource_specification) ? resource_specification.segment : controller_name
    end
      
    def remove_namespace(path)
      if namespace_segments.any?
        path.delete_prefix("/#{namespace_segments.join('/')}")
      else
        path
      end
    end
    
    def segments_for_path_and_keys(path, keys)
      key_segments = keys.map {|k| segment_for_key(k)}
      path_segments = path.delete_prefix('/').split('/')
      segments = []
      i = 0
      while i < path_segments.length
        segment = path_segments[i]
        if key_segments.include?(segment)
          segments << {:segment => segment, :singleton => false}
          i += 2 # swallow following :id
        else
          segments << {:segment => segment, :singleton => true}
          i += 1
        end
      end
      segments
    end
    
    def segment_for_key(key)
      key_str = key.to_s
      if respond_to?(:specifications) && (spec = specifications.find {|s| s.respond_to?(:key) && s.key == key_str})
        return spec.segment
      end

      resource_specification_map.each_value do |spec|
        return spec.segment if spec.key == key_str
      end

      key_str.delete_suffix('_id').pluralize
    end
  end
end
