module Ardes#:nodoc:
  module ResourcesController
    # This module provides methods are provided to aid in writing inheritable controllers.
    #
    # When writing an action that redirects to the list of resources, you may use *resources_url* and the controller
    # will call the url_writer method appropriate to what the controller is a resources controller for.
    #
    # If the route specified requires a member argument and you don't provide it, the current resource is used.
    #
    # In general you may subsitute 'resource' for the current (maybe polymorphic) resource. e.g.
    #
    #    (in attachable/attachments where attachable is a Post)
    #
    #    resources_path                        # => post_attachments_path
    #    formatted_edit_resource_path('js')    # => formatted_post_attachments_path(<current post>, <current attachment>, 'js')
    #    resource_tags_path                    # => post_attachments_tags_paths(<current post>, <current attachment>)
    #    resource_tags_path(foo)               # => post_attachments_tags_paths(<current post>, foo)
    #
    # These methods are defined as they are used.  The ActionView Helper module delegates to the current controller to access these
    # methods
    module UrlHelper
      def self.included(base)
        base.class_eval do
          alias_method_chain :method_missing, :url_helper
          alias_method_chain :respond_to?, :url_helper
        end
      end

      def method_missing_with_url_helper(method, *args, &block)
        # TODO: test that methods are only defined once
        if resource_url_helper_method?(method, raise_error = true) 
          define_resource_url_helper_method(method)
          send(method, *args)
        elsif resource_url_helper_method_for_name_prefix?(method)
          define_resource_url_helper_method_for_name_prefix(method)
          send(method, *args)
        else
          method_missing_without_url_helper(method, *args, &block)
        end
      end

      def respond_to_with_url_helper?(method)
        respond_to_without_url_helper?(method) || resource_url_helper_method?(method)
      end

      # return true if the passed method (e.g. 'resources_path') corresponds to a defined
      # named route helper method
      def resource_url_helper_method?(resource_method, raise_error = false)
        if resource_method.to_s =~ /_(path|url)$/ && resource_method.to_s =~ /(^|^.*_)resource(s)?_/
          route, route_method = *route_and_method_from_resource_method_and_name_prefix(resource_method, name_prefix)
          respond_to_without_url_helper?(route_method) || (raise_error && raise(NoMethodError, <<-end_str
Tried to map :#{resource_method} to :#{route_method}, which doesn't exist.
You may not have defined the route in config/routes.rb. Or, you may need to
explicictly set route_name and name_prefix in resources_controller_for.
Currently route_name is '#{route_name}' and name_prefix is '#{name_prefix}'
          end_str
          ))
        end
      end

    private
      # passed something like (^|.*_)resource(s)_.*(url|path)$, will 
      # return the [route, route_method]  for the expanded resource
      def route_and_method_from_resource_method_and_name_prefix(method, name_prefix)
        route_method = method.to_s.sub(/resource(s)?/) { $1 ? "#{name_prefix}#{route_name}" : "#{name_prefix}#{singular_route_name}" }
        return [ActionController::Routing::Routes.named_routes.get(route_method.sub(/_(path|url)$/,'').to_sym), route_method]
      end

      # defines a method that calls the appropriate named route method, with appropraite args.
      def define_resource_url_helper_method(method)
        self.class.send :module_eval, <<-end_eval, __FILE__, __LINE__
          def #{method}(*args)
            send "#{method}_for_\#{name_prefix}", *args
          end
        end_eval
      end

      def resource_url_helper_method_for_name_prefix?(method)
        method.to_s =~ /_for_.*$/ && resource_url_helper_method?(method.to_s.sub(/_for_.*$/,''))
      end

      def define_resource_url_helper_method_for_name_prefix(method)
        resource_method = method.to_s.sub(/_for_.*$/,'')
        name_prefix = method.to_s.sub(/^.*_for_/,'')
        route, route_method = *route_and_method_from_resource_method_and_name_prefix(resource_method, name_prefix)
        required_args = route.significant_keys.reject{|k| [:controller, :action].include?(k)}.size

        self.class.send :module_eval, <<-end_eval, __FILE__, __LINE__
          def #{method}(*args)
            options = args.last.is_a?(Hash) ? args.pop : {}
            #{"args = [resource] + args if enclosing_resources.size + args.size < #{required_args}" if required_args > 0}
            args = args + [options] if options.size > 0
            send :#{route_method}, *enclosing_resources + args
          end
        end_eval
        self.class.send :private, method
      end
    end
  end
end