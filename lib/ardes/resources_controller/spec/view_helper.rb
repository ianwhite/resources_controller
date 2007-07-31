module Ardes#:nodoc:
  module ResourcesController
    module Spec#:nodoc:
      # Easy view testing for resources_controller views
      #
      # === Example
      #
      #   describe "/attachments/edit.html.haml" do
      #     include Ardes::ResourcesController::Spec::ViewHelper
      #
      #     before do
      #       make_resources_controller!(@controller)
      #       @attachment = mock_attachment
      #       @controller.resource = @attachment # this sets resource_name, resource_class etc, etc
      #                                          # can also do @controller.resources = 
      #     end
      #
      #     it "should call form_for_resource" do
      #       template.should_receive(:form_for_resource)
      #       render "/attachments/edit.html.erb"
      #     end
      #
      #     it "should render edit form" do
      #       render "/attachments/edit.html.erb"
      #
      #       response.should have_tag("form[action=/attachments/#{@attachment.id}][enctype=multipart/form-data]") do
      #         with_tag("input[type=text][id=attachment_filename]")
      #         with_tag("input[type=file][id=attachment_uploaded_data]")
      #         with_tag("input[type=submit]")
      #       end
      #     end
      #   end
      #
      # TODO: write some view examples using this
      module ViewHelper
        # TODO: figure out how to do attach a before block when the module is included
        # this will mean you don't have to do make_resources_controller!
        def self.included(base)
          #base.before do
          #  make_resources_controller!(@controller)
          #end
        end
        
        # makes the passed test controller respond to various resources_controller methods, also includes
        # the Helper on the template
        def make_resources_controller!(controller = @controller)
          controller.metaclass.class_eval do
            include Ardes::ResourcesController::UrlHelper
            
            attr_accessor :route_name, :name_prefix, :resource_name, :resources_name, :enclosing_resources
            attr_reader :resource_class

            def singular_route_name
              route_name.singularize
            end

            def resource
              instance_variable_get("@#{resource_name}")
            end

            def resources
              instance_variable_get("@#{resources_name}")
            end

            def resource=(resource)
              self.resource_class = resource.class unless resource_class
              instance_variable_set("@#{resource_name}", resource)
            end

            def resources=(resources)
              self.resource_class = resources.first.class unless resource_class
              instance_variable_set("@#{resources_name}", resources)
            end

            def resource_class=(klass)
              @resource_class = klass
              self.resource_name = resource_class.name.underscore
              self.resources_name = resource_class.name.pluralize.underscore
              self.route_name = resources_name
            end
          end
          controller.enclosing_resources = []
          controller.name_prefix = ''

          controller.template.metaclass.class_eval do
            include Ardes::ResourcesController::Helper
          end
        end
      end
    end
  end
end