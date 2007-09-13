module Ardes#:nodoc:
  # With resources_controller (http://svn.ardes.com/rails_plugins/resources_controller) you can quickly add
  # an ActiveResource compliant controller for your your RESTful models.
  # 
  # = Examples
  # Here are some examples - for more on how to use  RC go to the Usage section at the bottom,
  # for syntax head to resources_controller_for
  #
  # ==== Example 1: Super simple usage
  # Here's a simple example of how it works with a Forums has many Posts model:
  # 
  #   class ForumsController < ApplicationController
  #     resources_controller_for :forums
  #   end
  #
  # Your controller will get the standard CRUD actions, @forum will be set in member actions, @forums in
  # index.
  # 
  # ==== Example 2: Specifying enclosing resources
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts, :in => :forum
  #   end
  #
  # As above, but the controller will load @forum on every action, and use @forum to find and create @posts
  #
  # ==== Wildcard enclosing resources
  # All of the above examples will work for any routes that match what it specified
  #
  #              PATH                     RESOURCES CONTROLLER WILL DO:
  #
  #  Example 1  /forums                   @forums = Forum.find(:all)
  #
  #             /users/2/forums           @user = User.find(2)
  #                                       @forums = @user.forums.find(:all)
  #
  #  Example 2  /posts                    @posts = Post.find(:all)
  #
  #             /forums/2/posts           @forum = Forum.find(2)
  #                                       @posts = @forum.posts.find(:all)
  #
  #             /sites/4/forums/3/posts   @site = Site.find(4)
  #                                       @forum = @site.forums.find(3)
  #                                       @posts = @forum.posts.find(:all)
  #
  #             /users/2/posts/1          This won't work as the controller specified
  #                                       that :posts are :in => :forum
  #                                       
  #
  # It is up to you which routes to open to the controller (in config/routes.rb).  When
  # you do, RC will use the route segments to drill down to the specified resource.  This means
  # that if User 3 does not have Post 5, then /users/3/posts/5 will raise a RecordNotFound Error.
  # You dont' have to write any extra code to do this oft repeated controller pattern.
  #
  # With RC, your route specification flows through to the controller - no need to repeat yourself.
  #
  # If you don't want to have RC match wildcard resources just pass :load_enclosing => false
  #
  #   resources_controller_for :posts, :in => :forum, :load_enclosing => 'false'
  #
  # ==== Example 3: Singleton resource
  # Here's an example of a singleton, the account pattern that is so common.
  #
  #   class AccountController < ApplicationController
  #     resources_controller_for :account, :class => User, :singleton => true do
  #       @current_user
  #     end
  #   end
  #
  # Your controller will use the block to find the resource.  The @account will be assigned to @current_user
  #
  # ==== Example 4: Allowing PostsController to be used all over
  # First thing to do is remove :in => :forum
  #
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts
  #   end
  #
  # This will now work for /users/2/posts.
  #
  # ==== Example 4 and a bit: Mapping non standard resources
  # How about /account/posts?  The account is found in a non standard way - RC won't be able
  # to figure out how tofind it if it appears in the route.  So we give it some help.
  #
  # (in PostsController)
  #
  #   map_resource :account, :singleton => true, :class => User, :find => :current_user
  # 
  # Now, if :account apears in any part of a route (for PostsController) it will be mapped to
  # (in this case) the current_user method of teh PostsController.
  #
  # To make the :account mapping available to all, just chuck it in ApplicationController
  # 
  # This will work for any resource which can't be inferred from its route segment name
  #
  #   map_resource :peeps, :source => :users
  #   map_resource :posts, :class => BadlyNamedPostClass
  #
  # ==== Example 5: Singleton association
  # Here's another singleton example - one where it corresponds to a has_one or belongs_to association
  #
  #   class ImageController < ApplicationController
  #     resources_controller_for :image, :singleton => true
  #   end
  #
  # When invoked with /users/3/image RC will find @user, and use @user.image to find the resource, and
  # @user.build_image, to create a new resource. 
  #
  # ==== Putting it all together
  #
  # An exmaple app
  #
  # config/routes.rb:
  #  
  #  map.resource :account do |account|
  #    account.resource :image
  #    account.resources :posts
  #  end
  #
  #  map.resources :users do |user|
  #    user.resource :image
  #    user.resources :posts
  #  end
  #
  #  map.resources :forums do |forum|
  #    forum.resources :posts
  #    forum.resource :image
  #  end
  #
  # app/controllers:
  #
  #  class ApplicationController < ActionController::Base
  #    map_resource :account, :singleton => true, :find => :current_user
  #
  #    def current_user # get it from session or whatnot
  #  end
  #
  #  class ForumsController < AplicationController
  #    resources_controller_for :forums
  #  end
  #    
  #  class PostsController < AplicationController
  #    resources_controller_for :posts
  #  end
  #
  #  class UsersController < AplicationController
  #    resources_controller_for :users
  #  end
  #
  #  class ImageController < AplicationController
  #    resources_controller_for :image, :singleton => true
  #  end
  #
  #  class AccountController < ApplicationController
  #    resources_controller_for :account, :singleton => true, :find => :current_user
  #  end
  #
  # This is how the app will handle the following routes:
  #
  #  PATH                   CONTROLLER    WHICH WILL DO:
  #  
  #  /forums                forums        @forums = Forum.find(:all)
  #  
  #  /forums/2/posts        posts         @forum = Forum.find(2)
  #                                       @posts = @forum.forums.find(:all)
  #
  #  /forums/2/image        image         @forum = Forum.find(2)
  #                                       @image = @forum.image   
  #  
  #  /image                       <no route>
  #
  #  /posts                       <no route>
  #
  #  /users/2/posts/3       posts         @user = User.find(2)
  #                                       @post = @user.posts.find(3)
  #  
  #  /users/2/image POST    image         @user = User.find(2)
  #                                       @image = @user.build_image(params[:image])
  #
  #  /account               account       @account = self.current_user
  #
  #  /account/image         image         @account = self.current_user
  #                                       @image = @account.image
  #
  #  /account/posts/3 PUT   posts         @account = self.current_user
  #                                       @post = @account.posts.find(3)
  #                                       @post.update_attributes(params[:post])
  #
  # === Views
  #
  # Ok - so how do I write the views?  
  #
  # For most cases, just in exactly the way you would expect to.  RC sets the instance variables
  # to what they should be.
  #
  # But, in some cases, you are going to have different variables set - for example
  #
  #   /users/1/posts    =>  @user, @posts
  #   /forums/2/posts   =>  @forum, @posts
  # 
  # Here are some options (all are appropriate for different circumstances):
  # * test for the existence of @user or @forum in the view, and display it differently
  # * have two different controllers UserPostsController and ForumPostsController, with different views
  #   (and direct the routes to them in routes.rb)
  # * use enclosing_resource - which always refers to the... immediately enclosing resource.
  #
  # Using the last technique, you might write your posts index as follows
  # (here assuming that both Forum and User have .name)
  #
  #   <h1>Posts for <%= link_to enclosing_resource_path, "#{enclosing_resource_name.humanize}: #{enclosing_resource.name}" %></h1>
  #
  #   <%= render :partial => 'post', :collection => @posts %>
  #
  # Notice *enclosing_resource_name* - this will be something like 'user', or 'post'.
  # Also *enclosing_resource_path* - in RC you get all of the named route helpers relativised to the current resource
  # and enclosing_resource.  See NamedRouteHelper for more details.
  #
  # This can useful when writing the _post partial:
  #
  #   <p>
  #     <%= post.name %>
  #     <%= link_to 'edit', edit_resource_path(tag) %>
  #     <%= link_to 'destroy', resource_path(tag), :method => :delete %>
  #   </p>
  #
  # when viewed at /users/1/posts it will show
  #
  #  <p>
  #    Cool post
  #    <a href="/users/1/posts/1/edit">edit</a>
  #    <a href="js nightmare with /users/1/posts/1">delete</a>
  #  </p>
  #  ...
  #
  # when viewd at /forums/1/posts it will show
  #
  #  <p>
  #    Other post
  #    <a href="/forums/1/posts/3/edit">edit</a>
  #    <a href="js nightmare with /forums/1/posts/3">delete</a>
  #  </p>
  #  ...
  #
  # This is like polymorphic urls, except that RC will just use whatever enclosing resources are loaded to generate the urls/paths.
  #
  # = Usage
  # To use RC, there are just three class methods on controller to learn.
  #
  # resources_controller_for <name>, <options>, <&block>
  #
  # ClassMethods#nested_in <name>, <options>, <&block>
  #
  # map_resource <name>, <options>, <&block>
  #
  # === Customising finding and creating
  # If you want to implement something like query params you can override *find_resources*.  If you want to change the 
  # way your new resources are created you can override *new_resource*.
  #
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts
  # 
  #     def find_resources
  #       resource_service.find :all, :order => params[:sort_by]
  #     end
  #
  #     def new_resource
  #       returning resource_service.new(params[resource_name]) do |post|
  #         post.ip_address = request.remote_ip
  #       end
  #     end
  #   end
  #
  # In the same way, you can override *find_resource*.
  #
  # === Writing controller actions
  #
  # You can make use of RC internals to simplify your actions.
  #
  # Here's an example where you want to re-order an acts_as_list model.  You define a class method
  # on the model (say *order_by_ids* which takes and array of ids).  You can then make use of *resource_service*
  # (which makes use of awesome rails magic) to send correctly scoped messages to your models.
  #
  # Here's how to write an order action
  #
  #   def order
  #     resource_service.order_by_ids["things_order"]
  #   end
  #
  # the route
  #
  #   map.resources :things, :collection => {:order => :put}
  #
  # and the view can conatin a scriptaculous drag and drop with param name 'things_order'
  #
  # When this controller is invoked of /things the :order_by_ids message will be sent to the Thing class,
  # when it's invoked by /foos/1/things, then :order_by_ids message will be send to Foo.find(1).things association
  module ResourcesController
    def self.extended(base)
      base.class_eval do
        class_inheritable_reader :resource_specification_map
        write_inheritable_attribute(:resource_specification_map, {})
      end
    end
    
    # Specifies that this controller is a REST style controller for the named resource
    #
    # Enclosing resources are loaded automatically by default, you can turn this off with
    # :load_enclosing (see options below)
    #
    # resources_controller_for <name>, <options>, <&block>
    #
    # ==== Options:
    # * <tt>:singleton:</tt> (default false) set this to true if the resource is a Singleton
    # * <tt>:find:</tt> (default null) set this to a symbol or Proc to specify how to find the resource.
    #   Use this if the resource is found in an unconventional way.  Passing a block has the same effect as
    #   setting :find => a Proc
    # * <tt>:in:</tt> specify the enclosing resources, by name.  ClassMethods#nested_in can be used to 
    #   specify this more fully.
    # * <tt>:load_enclosing:</tt> (default true) loads enclosing resources automatically.
    # * <tt>:actions:</tt? (default nil) set this to false if you don't want the default RC actions.  Set this
    #   to a module to define your own actions.
    #
    # =====Options for unconvential use
    # (otherwise these are all inferred from the _name_)
    # * <tt>:route:</tt> the route name (without name_prefix) if it can't be inferred from _name_.
    #   For a collection resource this should be plural, for a singleton it should be singular.
    # * <tt>:source:</tt> a string or symbol (e.g. :users, or :user).  This is used to find the class or association name
    # * <tt>:class:</tt> a Class.  This is the class of the resource (if it can't be inferred from _name_ or :source)
    # * <tt>:key:</tt> (e.g. :user_id) used to find the resource id in params
    # * <tt>:segment:</tt> (e.g. 'users') the segment name in the route that is matched
    #
    # === The :in option
    # The default behavior is to set up before filters that load the enclosing resource, and to use associations on
    # that model to find and create the resources.  See ClassMethods#nested_in for more details on this, and
    # customising the default behaviour.
    #
    def resources_controller_for(name, options = {}, &block)
      deprecated_resources_controller_for(options)
      if included_modules.include?(ResourcesController::InstanceMethods)
        raise ArgumentError, "controller is already resources_controller for '#{self.resource_name}'"
      end
      
      options.assert_valid_keys(:class, :source, :singleton, :actions, :in, :find, :load_enclosing, :route, :segment)
      
      class_inheritable_reader :resource_specification, :specifications, :route_name
      write_inheritable_attribute(:specifications, [])
      
      extend  ResourcesController::ClassMethods
      helper  ResourcesController::Helper
      include ResourcesController::InstanceMethods, ResourcesController::NamedRouteHelper
      
      if actions = options.delete(:actions)
        include actions
      elsif actions.nil?
        include options[:singleton] ? ResourcesController::SingletonActions : ResourcesController::Actions
      end
      
      route = (options.delete(:route) || name).to_s
      name = options[:singleton] ? name.to_s : name.to_s.singularize
      write_inheritable_attribute :route_name, options[:singleton] ? route : route.singularize
      
      prepend_before_filter :load_enclosing_resources
      specifications << '*' unless options.delete(:load_enclosing) == false
      if nested = options.delete(:in)
        nested_in(*nested)
      end
      
      write_inheritable_attribute(:resource_specification, Specification.new(name, options, &block))
    end
    
    def deprecated_resources_controller_for(options)
      options[:class] ||= options[:class_name] && options[:class_name].constantize
      options[:source] ||= options[:collection_name]
      options[:actions] = options[:actions_include] if options[:actions].nil?
      options[:route] ||= options[:route_name]
      [:class_name, :collection_name, :actions_include, :route_name].each do |k|
        if options.key?(k)
          ActiveSupport::Deprecation.warn("option :#{k} has been deprecated for resources_controller_for and will be removed soon")
          options.delete(k)
        end
      end
    end
    
    # Creates a resource specification mapping.  Use this to specify how to find an enclosing resource that
    # does not obey usual rails conventions.  Most commonly this would be a singleton resource.
    #
    # See Specification#new for details of how to call this
    def map_resource(name, options = {}, &block)
      resource_specification_map[name.to_s] = Specification.new(name, options, &block)
    end
    
    module ClassMethods
      # Specifies that this controller has a particular enclosing resource.
      #
      # See Specification#new for details of how to call this.
      def nested_in(*names, &block)
        options = names.last.is_a?(Hash) ? names.pop : {}
        raise ArgumentError, "when giving more than one nesting, you may not specify options or a block" if names.length > 1 and (block_given? or options.length > 0)
        deprecated_nested_in(options)
        names.each do |name|
          specifications << (name.to_s == '*' ? '*' : Specification.new(name, options, &block))
        end
      end
      
      def deprecated_nested_in(options)
        options[:class] ||= options[:class_name] && options[:class_name].constantize
        options[:source] ||= options[:collection_name]
        options[:key] ||= options[:foreign_key]
        [:class_name, :collection_name, :load_enclosing, :polymorphic, :foreign_key].each do |k|
          if options.key?(k)
            ActiveSupport::Deprecation.warn("option :#{k} has been deprecated for nested_in and will be removed soon")
            options.delete(k)
          end
        end      
      end
    end
    
    module InstanceMethods
      def self.included(base)
        base.send :hide_action, *instance_methods
        base.class_eval do
          attr_writer :resource_service
          
        protected
          # we define the find|new_resource(s) methods only if they're not already defined
          # this allows abstract controllers to define the resource service methods
          unless instance_methods.include?('find_resources')
            # finds the collection of resources
            def find_resources
              resource_service.find :all
            end
          end

          unless instance_methods.include?('find_resource')
            # finds the resource, using the passed id
            def find_resource(id = params[:id])
              resource_service.find id
            end
          end

          unless instance_methods.include?('new_resource')
            # makes a new resource, optionally using the passed hash
            def new_resource(attributes = params[resource_name])
              resource_service.new attributes
            end
          end
        end
      end
      
      def name_prefix
        @name_prefix ||= ''
      end
      
      # name of the singular resource
      def resource_name
        resource_specification.name
      end
      
      # name of the resource collection
      def resources_name
        @resources_name ||= resource_specification.name.pluralize
      end
      
      # returns the controller's resource class
      def resource_class
        resource_specification.klass
      end
      
      # returns the controller's current resource
      def resource
        instance_variable_get("@#{resource_name}")
      end
      
      # sets the controller's current resource
      def resource=(record)
        instance_variable_set("@#{resource_name}", record)
      end
  
      # returns the controller's current resources collection
      def resources
        instance_variable_get("@#{resources_name}")
      end
      
      # sets the controller's current resource collection
      def resources=(collection)
        instance_variable_set("@#{resources_name}", collection)
      end
      
      # returns the immediately enclosing resource
      def enclosing_resource
        enclosing_resources.last
      end
      
      # returns the name of the immediately enclosing resource
      def enclosing_resource_name
        enclosing_resource && @enclosing_resource_name ||= enclosing_resource.class.name.underscore
      end
        
      def resource_service
        @resource_service ||= resource_specification.singleton? ? SingletonResourceService.new(self) : ResourceService.new(self)
      end
      
    protected
      # returns an array of the controller's enclosing (nested in) resources
      def enclosing_resources
        @enclosing_resources ||= []
      end
  
      # returns an array of the non singleton enclosing resources, this is used for generating routes.
      def non_singleton_resources
        @non_singleton_resources ||= []
      end

    private
      # returns the route that was used to invoke this controller and current action
      def recognized_route
        @recognized_route ||= ::ActionController::Routing::Routes.routes_for_controller_and_action(controller_name, action_name).find do |route|
          route.recognize(request.path, ::ActionController::Routing::Routes.extract_request_environment(request))
        end
        @recognized_route or raise RuntimeError, <<-end_str
resources_controller could not recognize a route that that the controller
was invoked with.  This is probably being raised in a test.

The controller name is '#{controller_name}'
The request.path is '#{request.path}'
The route request environment is:
  #{::ActionController::Routing::Routes.extract_request_environment(request).inspect}

Possible reasons for this:
- routes have not been loaded
- the controller has been invoked with params that don't correspond to a
  route (and so would never be invoked in a real app)
- the test can't figure out which route corresponds to the params, in this 
  case you may need to stub the recognized_route. (rspec example:)
  @controller.stub!(:recognized_route).and_return(ActionController::Routing::Routes.named_routes[:the_route])
  
        end_str
      end
      
      # returns the all route segments except for the ones corresponding to the current resource and action
      def enclosing_route_segments
        segments = recognized_route.segments.dup
        while segments.size > 0
          segment = segments.pop
          return segments if segment.is_a?(::ActionController::Routing::StaticSegment) && segment.value == resource_specification.segment
        end
        ResourcesController.raise_missing_route_segment(self)
      end
      
      # Returns an array of pairs [<name>, <singleton?>] e.g. [[users, false], [blog, true], [posts, false]]
      # corresponding to the enclosing resources.
      #
      # This is used to map resources and automatically load resources.
      def route_resource_names
        @route_resource_names ||= returning(Array.new) do |req|
          enclosing_route_segments.each do |segment|
            unless segment.is_optional or segment.is_a?(::ActionController::Routing::DividerSegment)
              req << [segment.value, true] if segment.is_a?(::ActionController::Routing::StaticSegment)
              req.last[1] = false if segment.is_a?(::ActionController::Routing::DynamicSegment)
            end
          end
        end
      end
      
      # this is the before_filter that 
      # * loads all specified and wilcard resources
      # * sets the controller instance to the current resource specification
      def load_enclosing_resources
        specifications.each_with_index do |spec, idx|
          spec == '*' ? load_wildcards(specifications[idx+1]) : spec.load_into(self)
        end
        resource_specification.controller = self
      end
    
      # loads resoources from the route segments, using the segment names to either
      # * map to a specification, or
      # * create a specification using the segment name
      def load_wildcards(to_spec)
        return if to_spec == '*'
        route_resource_names.slice(enclosing_resources.size..-1).each do |segment, singleton|
          return if to_spec && to_spec.segment == segment
          name = singleton ? segment : segment.singularize
          if resource_specification_map[name]
            resource_specification_map[name].load_into(self)
          else
            Specification.new(name, :singleton => singleton).load_into(self)
          end
        end
      end
      
      # The name prefix is used for forwarding urls.  This is different dependning on
      # which route the controller was invoked by.  The resource spcifications build
      # up the name prefix as the resources are loaded.
      def update_name_prefix(name_prefix)
        @name_prefix = "#{@name_prefix}#{name_prefix}"
      end
    end
    
    # Proxy class to provide a consistent API for resource_service.  This is mostly
    # required for Singleton resources. Also allows decoration of the resource service with custom finders
    class ResourceService < Builder::BlankSlate
      attr_reader :controller
      delegate :resource_specification, :resource_class, :enclosing_resource, :to => :controller
      
      def initialize(controller)
        @controller = controller
      end
            
      def method_missing(*args, &block)
        service.send(*args, &block)
      end
      
      def find(*args, &block)
        resource_specification.find ? resource_specification.find_custom : super
      end
      
      def respond_to?(method)
        super || service.respond_to?(method)
      end
    
      def service
        @service ||= enclosing_resource ? enclosing_resource.send(resource_specification.source) : resource_class
      end
    end
    
    class SingletonResourceService < ResourceService
      def find(*args)
        if resource_specification.find
          resource_specification.find_custom
        elsif enclosing_resource
          enclosing_resource.send(resource_specification.source)
        else
          ResourcesController.raise_cant_find_singleton(controller.resource_name, controller.resource_class)
        end
      end

      # build association on the enclosing resource if there is one
      def new(*args)
        enclosing_resource ? enclosing_resource.send("build_#{resource_specification.source}", *args) : super
      end

      def service
        resource_class
      end
    end
    
    class CantFindSingleton < RuntimeError #:nodoc:
    end

    class MissingRouteSegment < RuntimeError #:nodoc:
    end

    class << self
      def raise_cant_find_singleton(name, klass) #:nodoc:
        raise CantFindSingleton, <<-end_str
Can't get singleton resource from class #{klass.name}. You have have probably done something like:

  nested_in :#{name}, :singleton => true  # <= where this is the first nested_in

You should tell resources_controller how to find the singleton resource like this:

  nested_in :#{name}, :singleton => true do
    #{klass.name}.find(<.. your find args here ..>)
  end

Or: 
  nested_in :#{name}, :singleton => true, :find => <.. method name or lambda ..>

Or, you may be relying on the route to load the resource, in which case you need to give RC some
help.  Do this by mapping the route segment to a resource in the controller, or a parent or mixin

  map_resource :#{name}, :singleton => true <.. as above ..>
end_str
      end

      def raise_missing_route_segment(controller) #:nodoc:
        raise MissingRouteSegment, <<-end_str
Could not recognize segment '#{controller.resource_specification.segment}' in route:
  #{controller.send(:recognized_route)}

Check that config/routes.rb defines a route named '#{controller.name_prefix}#{controller.resource_specification.singleton? ? controller.route_name.pluralize : controller.route_name}'
  for controller: #{controller.controller_name.camelize}Controller"
end_str
      end
    end
  end
end
