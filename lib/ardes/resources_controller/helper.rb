module Ardes#:nodoc:
  module ResourcesController
    # Often it won't be appropriate to re-use views, but
    # sometimes it is.  These helper methods enable reuse by referencing whatever resource the 
    # controller is for.
    #
    # ==== Example:
    #
    # instead of writing:
    #  <% for event in @events %>
    #    <%= link_to 'edit', edit_event_path(event) %>
    #
    # you may write:
    #  <% for event in resources %>
    #    <%= link_to 'edit', edit_resource_path(event) %>
    #
    # == Enclosing named routes:
    #
    # In addition you can reference named routes that are 'below' the current resource
    # by appending resource_ to that named route.
    #
    # ==== Example: shared polymorphic view
    #
    # Let's say you have a resource controller for tags, and you're writing the 
    # taggable views.  In a view shared amongst taggables you can write
    #
    #  <%= link_to 'tags', resource_tags_path %>
    #  <%= link_to 'edit tag', edit_resource_tag_path(@tag) %>
    # 
    # or:
    #  <% for taggable in resources %>
    #    <%= link_to 'tags', resource_tags_path(taggable) %>
    #
    # See UrlHelpers for more detail
    module Helper
      def self.included(base)
        base.class_eval do
          alias_method_chain :method_missing, :url_helper
          alias_method_chain :respond_to?, :url_helper
        end
      end

      # Calls form_for with the apropriate action and method for the resource
      #
      # resource.new_record? is used to decide between a create or update action
      #
      # You can optionally pass a resource object, default is to use self.resource
      #
      # === Example
      # 
      #   <% form_for_resource do |f| %>
      #     <%= f.text_field :name %>
      #     <%= f.submit resource.new_record? ? 'Create' : 'Update'
      #   <% end %>
      #
      #   <% for attachment in resources %>
      #     <% form_for_resource attachment, :html => {:multipart => true} %>
      #       <%= f.file_field :uploaded_data %>
      #       <%= f.submit 'Update' %>
      #     <% end %>
      #   <% end %>
      #
      def form_for_resource(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        resource = args[0] || self.resource
        options[:html]          ||= {}
        options[:html][:method] ||= resource.new_record? ? :post : :put
        options[:url]           ||= resource.new_record? ? resources_path : resource_path
        form_for(resource_name, resource, options, &block)
      end

      def remote_form_for_resource(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        resource = args[0] || self.resource
        options[:html]          ||= {}
        options[:html][:method] ||= resource.new_record? ? :post : :put
        options[:url]           ||= resource.new_record? ? resources_path : resource_path
        remote_form_for(resource_name, resource, options, &block)
      end

      def resource_name
        controller.resource_name
      end

      def resources_name
        controller.resources_name
      end

      def resource
        controller.resource
      end

      def resources
        controller.resources
      end
      
      def enclosing_resource
        controller.enclosing_resource
      end

      # delegate url helper method to the controller
      def method_missing_with_url_helper(method, *args, &block)
        if controller.resource_url_helper_method?(method) 
          self.class.send :module_eval, "def #{method}(*args); controller.#{method}(*args); end"
          controller.send(method, *args)
        else
          method_missing_without_url_helper(method, *args, &block)
        end
      end

      # delegate url help method creation to the controller
      def respond_to_with_url_helper?(method)
        respond_to_without_url_helper?(method) || controller.resource_url_helper_method?(method)
      end
    end
  end
end
