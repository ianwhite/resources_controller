# frozen_string_literal: true

module ResourcesController
  
  class CantMapRoute < ArgumentError #:nodoc:
  end
  
  # This module provides methods to aid in writing inheritable controllers.
  #
  # When writing an action that redirects to the list of resources, you may use *resources_url* and the controller
  # will call the url_writer method appropriate to what the controller is a resources controller for.
  #
  # If the route specified requires a member argument and you don't provide it, the current resource is used.
  #
  # In general you may substitute 'resource' for the current (maybe polymorphic) resource. e.g.
  #
  # You may also substitute 'enclosing_resource' to get urls for the enclosing resource
  #
  #    (in attachable/attachments where attachable is a Post)
  #
  #    resources_path                        # => post_attachments_path
  #    formatted_edit_resource_path('js')    # => formatted_post_attachments_path(<current post>, <current attachment>, 'js')
  #    resource_tags_path                    # => post_attachments_tags_paths(<current post>, <current attachment>)
  #    resource_tags_path(foo)               # => post_attachments_tags_paths(<current post>, foo)
  #
  #    enclosing_resource_path               # => post_path(<current post>)
  #    enclosing_resources_path              # => posts_path
  #    enclosing_resource_tags_path          # => post_tags_path(<current post>)
  #    enclosing_resource_path(2)            # => post_path(2)
  #
  # The enclosing_resource stuff works with deep nesting if you're into that.
  #
  # These methods are defined as they are used.  The ActionView Helper module delegates to the current controller to access these
  # methods
  module NamedRouteHelper

    def method_missing(method, ...)
      # TODO: test that methods are only defined once
      if resource_named_route_helper_method?(method, true)
        define_resource_named_route_helper_method(method)
        send(method, ...)
      elsif resource_named_route_helper_method_for_name_prefix?(method)
        define_resource_named_route_helper_method_for_name_prefix(method)
        send(method, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      resource_named_route_helper_method?(method) || super
    end

    # return true if the passed method (e.g. 'resources_path') corresponds to a defined
    # named route helper method (checked via respond_to? without querying named_routes)
    def resource_named_route_helper_method?(resource_method, raise_error = false)
      method_str = resource_method.to_s
      return false unless method_str.end_with?('_path', '_url')

      if method_str.include?('enclosing_resource')
        route_method = route_method_from_enclosing_resource_method_and_name_prefix(method_str, name_prefix)
      elsif method_str.include?('resource')
        route_method = route_method_from_resource_method_and_name_prefix(method_str, name_prefix)
      else
        return false
      end

      respond_to?(route_method, true) || (raise_error && raise_resource_url_mapping_error(resource_method, route_method))
    end

  private
    def raise_resource_url_mapping_error(resource_method, route_method)
      raise CantMapRoute, <<-end_str
Tried to map :#{resource_method} to :#{route_method},
which doesn't exist. You may not have defined the route in config/routes.rb.

Or, if you have unconventional route names or name prefixes, you may need
to explicitly set the :route option in resources_controller_for, and set
the :name_prefix option on your enclosing resources.

Currently:
:route is '#{route_name}'
generated name_prefix is '#{name_prefix}'
      end_str
    end
    
    def route_method_from_enclosing_resource_method_and_name_prefix(method, name_prefix)
      unless enclosing_resource
        raise NoMethodError, "Tried to map :#{method} but there is no enclosing_resource for this controller"
      end

      enclosing_route = name_prefix.delete_suffix('_')
      method_str = method.to_s
      is_plural = method_str.include?('enclosing_resources')
      substitution = is_plural ? enclosing_route.pluralize : enclosing_route
      method_str.sub(is_plural ? 'enclosing_resources' : 'enclosing_resource', substitution)
    end

    # passed something like (^|.*_)enclosing_resource(s)_.*(url|path)\z, will
    # return the [route, route_method]  for the expanded resource
    def route_and_method_from_enclosing_resource_method_and_name_prefix(method, name_prefix)
      route_method = route_method_from_enclosing_resource_method_and_name_prefix(method, name_prefix)
      [named_route_for_helper_method(route_method), route_method]
    end

    def route_method_from_resource_method_and_name_prefix(method, name_prefix)
      method_str = method.to_s
      is_resources = method_str.include?('resources_')
      replacement = "#{name_prefix}#{is_resources ? resources_route_name : route_name}"
      method_str.sub(is_resources ? 'resources' : 'resource', replacement)
    end

    # passed something like (^|.*_)resource(s)_.*(url|path)\z, will
    # return the [route, route_method]  for the expanded resource
    def route_and_method_from_resource_method_and_name_prefix(method, name_prefix)
      route_method = route_method_from_resource_method_and_name_prefix(method, name_prefix)
      [named_route_for_helper_method(route_method), route_method]
    end

    def named_route_for_helper_method(route_method)
      route_key = route_method.delete_suffix(route_method.end_with?('_path') ? '_path' : '_url')
      Rails.application.routes.named_routes.get(route_key.to_sym)
    end

    # route_name is fixed for the life of the controller, and pluralize is the most
    # expensive operation on this path, so it is memoised rather than run per call.
    def resources_route_name
      @resources_route_name ||= route_name.pluralize
    end
    
    # defines a method that calls the appropriate named route method, with appropriate args.
    def define_resource_named_route_helper_method(method)
      self.class.send :module_eval, <<-end_eval, __FILE__, __LINE__
        def #{method}(...)
          if name_prefix.to_s.empty?
            #{method}_for_(...)
          else
            send(:"#{method}_for_\#{name_prefix}", ...)
          end
        end
      end_eval
    end

    def resource_named_route_helper_method_for_name_prefix?(method)
      method_str = method.to_s
      idx = method_str.index('_for_')
      return false unless idx

      resource_named_route_helper_method?(method_str[0, idx])
    end

    def extract_resource_url_options(args)
      du_opts = default_url_options
      if args.last.is_a?(Hash) && args.last.extractable_options?
        options = args.pop
        options.merge!(du_opts) unless du_opts.empty?
        options
      elsif !du_opts.empty?
        du_opts.dup
      end
    end

    def define_resource_named_route_helper_method_for_name_prefix(method)
      method_str = method.to_s
      resource_method, name_prefix = method_str.split('_for_', 2)
      if resource_method.include?('enclosing_resource')
        route, route_method = route_and_method_from_enclosing_resource_method_and_name_prefix(resource_method, name_prefix)
        required_args = (route.segment_keys - [:format, :locale]).size

        self.class.send :module_eval, <<-end_eval, __FILE__, __LINE__
          def #{method}(*args)
            options = extract_resource_url_options(args)
            encl = args.size < #{required_args} ? enclosing_collection_resources : enclosing_collection_resources - [enclosing_resource]
            args << options if options && !options.empty?
            #{route_method}(*encl, *args)
          end
        end_eval

      else
        route, route_method = route_and_method_from_resource_method_and_name_prefix(resource_method, name_prefix)
        required_args = (route.segment_keys - [:format, :locale]).size

        self.class.send :module_eval, <<-end_eval, __FILE__, __LINE__
          def #{method}(*args)
            options = extract_resource_url_options(args)
            #{"args.unshift(resource) if enclosing_collection_resources.size + args.size < #{required_args}" if required_args > 0}
            args << options if options && !options.empty?
            #{route_method}(*enclosing_collection_resources, *args)
          end
        end_eval
      end
      
      self.class.send :private, method
    end
  end
end
