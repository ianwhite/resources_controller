module Ardes#:nodoc:
  # With resources_controller (http://svn.ardes.com/rails_plugins/resources_controller) you can quickly add
  # an ActiveResource compliant controller for your your RESTful models.
  # 
  # The intention is not to create an auto-scaffold, although it can be used for that.
  # The intention is to DRY up some of the repetitive code associated with controllers.
  # 
  # === Simple Usage
  # Here's a simple example of how it works with a Forums has many Posts model:
  # 
  #   class ForumsController < ApplicationController
  #     resources_controller_for :forums
  #   end
  # 
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts, :in => :forum
  #   end
  #
  #  class AccountController < ApplicationController
  #    resources_controller_for :account, :singleton => true, :class_name => 'User'
  #  protected
  #    def find_resource
  #      User.find(@current_user.id)
  #    end
  #  end
  # 
  # 
  # === Inheritance
  # But you can also use it to facilitate inheritance.  Let's say you have a Posts, User's Posts, and Forum's Posts controller,
  # that all respond to an atom feed on the index.  You would do it like this:
  # 
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts
  # 
  #     def index
  #       self.resources = find_resources
  #       respond_to do |format|
  #         format.html
  #         format.xml { render :xml => resources.to_xml }
  #         # custom atom response here
  #       end
  #     end
  #   end
  # 
  #   class UserPostsController < PostsController # notice inhertiance
  #     nested_in :user
  #   end
  # 
  #   class ForumPostsController < PostsController # notice inhertiance
  #     nested_in :forum
  #   end
  # 
  # === Customising nesting
  # If you have some funky stuff going when you set the @forum, you can specify it like this:
  # 
  #   class ForumPostsController < PostsController
  #     nested_in :forum do
  #       Forum.find_activated params[:forum_id]
  #     end
  #   end
  # 
  # === Customising finding, and creating
  # If you want to implement something like query params you can override *find_resources*.  If you want to change the 
  # way your new resources are created you can override *new_resource*.
  #
  #   class PostsController < ApplicationController
  #     resources_controller_for :forum
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
  # === resource_service
  # Internally, *resource_service* is used to find and create resources.  This is set to the resources
  # class for a simple, non-nested, resource.  It is set to a has_many collection for nested resources.
  # 
  # But you can set it to any object that responds to :find and :new.
  #
  # === Deeply nested resources
  #
  # Finally, it works for deeply nested controllers as well:
  # 
  #   class CommentsController < ApplicationController
  #     resources_controller_for :comments, :in => [:forum, :post]
  #   end
  # 
  # The above code will add two before filters:
  # 
  #   @forum = Forum.find params[:forum_id]
  #   @post = @forum.posts.find params[:post_id]
  # 
  # And sets the *resource_service* to:
  # 
  #   @post.comments
  #
  # === name_prefix
  #
  # For routing to work, the controller must derive, or be told about the name_prefix.  If the name_prefix is not
  # specified, it is derived by comparing the controller_name with the superclass controller_name.
  #
  # You can always set this yourself with self.name_prefix =
  #
  # Example
  #   class PostsController < ApplicationController
  #     resources_controller_for :posts # will use 'posts' as route_name, and '' as name_prefix
  #   end
  #
  #   class ForumPostsController < PostsController # notice inheritance
  #     nested_in :forum # will use 'posts' as route_name, and 'forum_' as name_prefix
  #   end
  #
  # === polymorphic, or anonymous, resources
  #
  # If you have a controller for a polymorhpic association, you can use one resources controller to service all of the routes.
  #   class TagsController < ApplicationController
  #     resources_controller_for :tags
  #     nested_in :taggable, :polymorphic => true
  #   end
  #   # This controller will work for routes with one level of nesting
  #   # e.g. forums/2/tags and users/2/tags
  #
  # If you want to have arbitrary nesting you can specify this with :load_enclosing
  #   class TagsController < ApplicationController
  #     resources_controller_for :tags
  #     nested_in :taggable, :polymorphic => true, :load_enclosing => true
  #   end
  #   # This controller will work for routes with multiple level of nesting
  #   #e.g. forums/2/tags, forums/2/posts/3/tags, forums/3/posts/1/comments/4/tags
  #
  # <b>Caveats for :anonymous and :load_enclosing</b>
  # * This will only work properly if your model names and collections all follow the usual Rails conventions.  If they don't you can use before_filters and the block for nested_in to set things up correctly.
  # * name_prefix is changed for each controller instance to reflect the way the resource was requested.  The usual conventions apply.
  #
  #   ActionController::Routing::Routes.draw do |map|
  #     map.resources :forums do |forums|
  #       forums.resources :tags, :name_prefix => 'forum_'
  #       forums.resources :posts do |posts|
  #         posts.resources :tags, :name_prefix => 'forum_post_'
  #         posts.resources :comments do |comments|
  #           comments.resources :tags, :name_prefix => 'forum_post_comment_'
  #         end
  #       end
  #     end
  #   end
  #
  # === Plays nice
  # The assigns for the view will all be what you expect them to be (@post, @comment, etc) and the same goes for the params hash.
  # 
  module ResourcesController
    # Specifies that this controller is a REST style controller for the named resource (a resources plural like :users, or a singleton resource like :account).  You can specify that the resource is a nested resource.
    #
    # Options:
    # * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    # * <tt>:collection_name:</tt> (synonym for :source)
    # * <tt>:source:</tt> The name of the association used to get the resource(s)
    # * <tt>:singleton:</tt> Default false, pass true if the resource is a singleton resource.  You may also pass a lambda which will be used to find the singleton.
    # * <tt>:singleton_find_options:</tt> Passed to the class for finding the singleton record
    # * <tt>:route_name:</tt> The name of the route (of the resources, i.e. :users), if it can't be inferred from the name of the controller
    # * <tt>:name_prefix:</tt> The name_prefix of the named route, if it cannot be inferred from the controller heirachy (see nested_in)
    # * <tt>:actions_include:</tt> A module, which will be included in the class, default is Ardes::ResourcesController::Actions, if set to false, no actions will be included.
    # * <tt>:in:</tt> Ordered array of singular model names which correspond to nesting a resource.
    # * <tt>:load_enclosing:</tt> Automagically load all of the enclosing resources, according to what route was used to invoke the controller
    #
    # Examples:
    #  
    #  # resources examples
    #
    #  resources_controller_for :users
    #  resources_controller_for :users, :class_name => 'Admin::Users', :actions_include => false
    #  resources_controller_for :users, :route_name => :admin_users, :actions_include => MyOwnActions
    #  resources_controller_for :posts, :in => :forum
    #  resources_controller_for :comments, :in => [:forum, :post]
    #
    #  # singleton resource examples
    #
    #  resources_controller_for :user, :singleton => lambda{ @current_user }
    #
    #  resources_controller_for :user, :singleton => true, :in => :forum, :source => :owner
    #
    #  # load enclosing
    #  resources_controller_for :tags, :load_enclosing => true
    #
    #    # if invoked by /forums/1/posts/2/tags/3 then the following will happen:
    #    #
    #    # @forum = Forum.find(1)
    #    # @post = @forum.posts.find(2)
    #    # @tag = @posts.tags.find(3)
    #
    #    # if invoked by /events/1/owner/tags/4 then the following will happen:
    #    #
    #    # @event = Event.find(1)
    #    # @owner = @event.owner
    #    # @tag = @owner.tags.find(4)
    #
    #
    #  resources_controller_for :owner, :singleton => true, :load_enclosing => true
    #
    #    # if invoked by /events/1/owner then the following will happen:
    #    #
    #    # @event = Event.find(1)
    #    # @owner = @event.owner
    #    
    #    # if invoked by /cats/3/owner
    #    #
    #    # @cat = Cat.find(3)
    #    # @owner = @cat.owner
    #  
    # === The :in option
    #
    # The default behavior is to set up before filters that load the enclosing resource, and to use associations on that
    # model to find and create the resources.  See nested_in for more details on this, and customising the default behaviour
    #
    def resources_controller_for(name, options = {})
      options.assert_valid_keys(:class_name, :collection_name, :source, :singleton, :actions_include, :route_name, :name_prefix, :in, :load_enclosing)
      
      self.class_eval do
        unless included_modules.include?(::Ardes::ResourcesController::InstanceMethods)
          class_inheritable_accessor  :resources_name, :resource_name, :resource_class, :resource_source,
            :resource_service_class, :enclosing_loaders, :name_prefix, :route_name, :find_singleton, :singleton
          
          self.enclosing_loaders = []
          
          include InstanceMethods
          include UrlHelper
          helper Helper
          
          options[:actions_include] = (options[:singleton] ? SingletonActions : Actions) if options[:actions_include].nil?
          
          prepend_before_filter :load_resources
        end
      end

      include options[:actions_include] if options[:actions_include]

      self.resource_source = options[:source] || options[:collection_name]
      
      if options[:singleton]
        self.singleton = true
        self.find_singleton = options[:singleton] if options[:singleton].is_a?(Proc)
        self.resources_name, self.resource_name = name.to_s.pluralize, name.to_s
        self.resource_service_class = SingletonResourceServiceProxy
        self.resource_source ||= self.resource_name
        self.route_name = (options[:route_name] || name).to_s
      else
        self.singleton = false
        self.resources_name, self.resource_name = name.to_s, name.to_s.singularize
        self.resource_source ||= self.resources_name
        self.route_name = (options[:route_name] || name).to_s.singularize
      end
      
      self.resource_class = (options[:class_name] || self.resource_name.camelize).constantize
      self.name_prefix    = options[:name_prefix] if options[:name_prefix]
      
      add_load_enclosing(true) if options[:load_enclosing]
      nested_in(*options[:in]) if options[:in]
    end
    
    # Specifies that the resource is nested in another resource.  Can be called in two ways:
    #
    #   nested_in :resource[, options] [&block]
    #   nested_in :resource1[, :resource2]...
    #
    # The latter version is equivalent to calling <tt>nested_in</tt> multiple times, and can only be used to provide the default functionality.
    #
    # The options for nested_in are
    # * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    # * <tt>:collection_name:</tt> synonym for :source
    # * <tt>:source:</tt> The association that the resource belongs to, if it can't be inferred from its name
    # * <tt>:foreign_key:</tt> The foreign key of the resource, if it can't be inferred from its name
    # * <tt>:polymorphic:</tt> synonym for anonymous
    # * <tt>:anonymous:</tt> set true if the nesting resource type should be inferred from the request
    # * <tt>:load_enclosing:</tt> set true if you want the enclosing resources to be inferred from the request.  This can only be used on the last nested_in.
    # * <tt>:name_prefix:</tt> The name_prefix of the named route, if it cannot be inferred from the controller heirachy (see nested_in).
    # * <tt>:singleton:</tt> Pass true if the resource is a singleton resource
    #
    # <b>:anonymous and :name_prefix</b> If :anonymous has been set to true the name_prefix will be inferred from the request, pass false to not change the name prefix
    #
    # === Examples
    # 
    # Calling <tt>nested_in :foo</tt> will result in the following:
    # * a before_filter which sets @foo according to params[:foo_id] (see load_enclosing_resource)
    # * resource_service will change from being the resource class to being @foo.resources association
    #
    # === customise load_enclosing before_filter
    # You can customise how the before_filter sets the nesting resource by passing a block which will be evaluated in the controller instance
    # the value of this block is assigned to the nesting resource instance_variable
    #  
    #  resource_controller_for :posts
    #  nested_in :forum do
    #    Forum.find(params[:forum_id])  # e.g. @forum = Forum.find(2) (if params[:forum_id] == 2)
    #  end
    #
    # (The above block just happens to be the default behaviour for a single nested controller)
    #
    #   resources_controller_for :info, :singular
    #   nested_in :user, :singleton => true do
    #     @current_user
    #   end
    
    # === Deep nesting
    # A typical resource that is multiply nested is found in the following way (example is forum has_many posts, each has_many comments):
    # 
    #  @forum = Forum.find(params[:forum_id])
    #  @post = @forum.posts.fiind(params[:post_id])
    #
    #  @comments = @post.comments.find(:all)
    #
    # The first nesting resource is found from the class, and subsequent ones are found from a collection.  Because of this the first, and subsequent
    # calls to nested_in have different options.
    #
    # * First nested_in: <tt>:class_name:</tt> the name of the class (e.g. 'Forum' in the above example) if it can't be inferred from the name
    # * Subsequent nested_ins:<tt>:source:</tt> the name of the collection (e.g. 'posts' in the above example) if it can't be inferred from the name
    #
    # === Example using options
    # If you're not using rails conventions that's ok.  Here's an example of how to do it
    # 
    # models are in Funky:: module, and collections are named 'the_*':
    #  
    #  class CommentsController < ApplicationController
    #    resources_controller_for :comments, :source => :the_comments   # @post.the_comments will be used as the resource_service
    #    nested_in :forum, :class_name => 'Funky::Forum'                # => Funky::Forum will be used to find @forum
    #    nested_in :posts, :source => 'the_posts'                       # => @forum.the_posts will be used to find @post
    #  end
    #
    # === Resource naming
    # However, if your models are named according to the usual conventions, it will just work.
    #
    #  class CommentsController < ApplicationController
    #    resources_controller_for :comments, :in => [:forum, :post]
    #  end
    #
    def nested_in(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}
      raise ArgumentError "when giving more than one nesting, you may not specify options or a block" if names.length > 1 and (block_given? or options.length > 0)
      names.each {|name| add_enclosing(name, options, &block)}
    end
    
    def map_enclosing_resource(name, options = {}, &block)
      enclosing_resource_map[name.to_s] = [options, block]
    end
    
  private
    def add_load_enclosing(load_all = false)
      raise RuntimeError, "you can only specify :load_enclosing => true once" if read_inheritable_attribute(:_added_load_enclosing)
      write_inheritable_attribute(:_added_load_enclosing, true)
      enclosing_loaders << [:load_enclosing_resources, [load_all]]
    end
      
    def add_enclosing(name, options = {}, &block)
      raise RuntimeError, "you can't add any more nested_ins after :load_enclosing => true" if read_inheritable_attribute(:_added_load_enclosing)
      
      options.assert_valid_keys(:polymorphic, :anonymous, :load_enclosing, :class_name, :collection_name, :foreign_key, :name_prefix, :singleton)
      options[:anonymous] = options[:anonymous] || options.delete(:polymorphic)
      
      unless options[:anonymous]
        name_prefix = options.delete(:name_prefix) || "#{name}_"
        self.name_prefix = "#{self.name_prefix}#{name_prefix}"
      end
      
      add_load_enclosing if options[:load_enclosing]
      enclosing_loaders << [:load_enclosing_resource, [name, options], block]
    end
    
    def enclosing_resource_map
      read_inheritable_attribute('_enclosing_resource_map') || write_inheritable_attribute('_enclosing_resource_map', {})
    end
    
    module InstanceMethods
      def self.included(base)
        base.send :hide_action, *instance_methods
        
        # the following accessors are set up to use the class attribute as default
        # and also to allow setting on the instance, without affecting the class attribute
        base.class_eval do
          attr_writer :name_prefix, :route_name
                    
          def route_name
            @route_name ||= self.class.route_name
          end
          
          def name_prefix
            @name_prefix ||= self.class.name_prefix
          end
          
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
      
      # returns the controller's current resource
      def resource
        instance_variable_get("@#{resource_name}")
      end
      
      # sets the controller's current resource
      def resource=(elem)
        instance_variable_set("@#{resource_name}", elem)
      end
  
      # returns the controller's current resources collection
      def resources
        instance_variable_get("@#{resources_name}")
      end
      
      # sets the controller's current resource collection
      def resources=(coll)
        instance_variable_set("@#{resources_name}", coll)
      end
      
      # returns the immediately enclosing resource
      def enclosing_resource
        @enclosing_resource ||= enclosing_resources.last
      end
    
      # returns the current resource service.  This is used to find and create resources.  This will
      # be either an ActiveRecord, or an association proxy, or a resource service proxy
      def resource_service
        @resource_service ||= if resource_service_class
          resource_service_class.new(self)
        elsif enclosing_resource
          enclosing_resource.send(resource_source)
        else
          resource_class
        end
      end
      
      # sets the current resource service, which is usually an ActiveRecord class, or an association proxy
      #
      # If you wish to provide a customised resource service you need to make sure the object responds
      # appropriately to:
      # * find :all
      # * find id
      # * new
      def resource_service=(service)
        @resource_service = service
      end
    
    private
      # returns an array of the controller's enclosing (nested in) resources
      def enclosing_resources
        @enclosing_resources ||= []
      end
  
      # returns an array of the enclosing resources used for routes (i.e. non-singleton enclosing resources)
      def route_resources
        @route_resources ||= []
      end

      def recognized_route
        routes =  ::ActionController::Routing::Routes.routes_by_controller[controller_name][action_name].values.flatten
        @recognized_route ||= routes.find do |route|
          route.recognize(request.path, ::ActionController::Routing::Routes.extract_request_environment(request))
        end
      end
      
      # returns an array containing hashes like {:name => resource name, :key => params key, :value => params value, :name_prefix => 'prefix segment'}
      # corresponding to the enclosing resources.
      def resources_request
        unless @resources_request
          enclosing_request = enclosing_route_segments.inject([]) do |request, segment|
            unless segment.is_optional or segment.is_a?(::ActionController::Routing::DividerSegment)
              if segment.is_a?(::ActionController::Routing::StaticSegment)
                request << {:name => segment.value}
              elsif segment.is_a?(::ActionController::Routing::DynamicSegment)
                request.last.merge!(:key => segment.key)
              end
            end
            request
          end
          enclosing_request.each do |request|
            request[:name_prefix] = (request[:key] ? request[:name].singularize : request[:name]) + '_'
          end
          @resources_request = enclosing_request
        end
        @resources_request
      end
      
      # pop off segments up to and including the current resource.  This will also remove any static action segments 
      def enclosing_route_segments
        segments = recognized_route.segments.dup
        route_name = singleton ? self.route_name : self.route_name.pluralize
        while segments.size > 0
          segment = segments.pop
          return segments if segment.is_a?(::ActionController::Routing::StaticSegment) and segment.value == route_name
        end
        raise "Could not recognize '#{route_name}' in '#{recognized_route}'" if segments.size == 0
      end
      
      def load_resources
        enclosing_loaders.each do |method|
          send(method[0], *(method[1] || []), &method[2])
        end
      end
      
      # load any remaining enclosing resources that nest the current nested_in
      def load_enclosing_resources(load_all = false)
        enclosing_request = resources_request.dup
        # ignore the lat request item if it's going to be loaded by a nested_in
        enclosing_request.pop unless load_all 

        enclosing_request.slice(enclosing_resources.size..-1).each do |request_item|
          load_enclosing_resource(request_item[:name], :anonymous => true, :singleton => !request_item[:key])
        end
      end
    
      def load_enclosing_resource(name, options = {}, &block)
        name = options[:singleton] ? name.to_s : name.to_s.singularize
        map = self.class.send(:enclosing_resource_map)
        if map[name]
          options = map[name].first.merge(:anonymous => true)
          block = map[name].last
        end
        enclosing_resource = block ? instance_eval(&block) : find_enclosing_resource(name, options)
        update_name_prefix(options[:name_prefix]) if options[:anonymous] && options[:name_prefix] != false
        enclosing_resources.push(enclosing_resource)
        route_resources.push(enclosing_resource) unless options[:singleton]
        instance_variable_set("@#{name}", enclosing_resource)
      end
    
      def update_name_prefix(name_prefix)
        name_prefix ||= resources_request[enclosing_resources.size][:name_prefix]
        self.name_prefix = "#{self.name_prefix}#{name_prefix}"
      end
    
      # This is the default method for finding an enclosing resource, if a block is not given to nested_in
      def find_enclosing_resource(name, options)
        source_name = options[:anonymous] ? resources_request[enclosing_resources.size][:name] : options[:class_name] || options[:source] || name
        
        if options[:singleton]
          raise_singleton_resource_find_error(name, source_name) if enclosing_resources.size == 0
          enclosing_resources.last.send(source_name)
        else
          id_key = options[:anonymous] ? resources_request[enclosing_resources.size][:key] : options[:foreign_key] || name.foreign_key
          source = enclosing_resources.size == 0 ? source_name.classify.constantize : enclosing_resources.last.send(source_name.tableize)
          source.find(params[id_key])
        end
      end
    
      def raise_singleton_resource_find_error(name, class_name)
        raise RuntimeError, <<-end_str
Can't get singleton resource from class #{class_name}. You have have probably done something like:

nested_in :#{name}, :singleton => true  # <= where this is the first nested_in

You should tell resources_controller how to find the singleton resource like this:

nested_in :#{name}, :singleton => true do
  #{class_name}.find(<.. your find args here ..>)
end

Or, you have :load_enclosing => true, and the route has a singleton resource as it's first segment.  In which
case you need to tell the controller how to find that resource.  Do this by:
  
map_resource :#{name}, options, { how to find }
end_str
      end
    end
    
    class ResourceServiceProxy < Builder::BlankSlate
      def initialize(controller)
        @_controller = controller
      end
      
      def method_missing(*args, &block)
        @_controller.enclosing_resource ? @_controller.enclosing_resource.send(*args, &block) : @_controller.resource_class.send(*args, &block)
      end
    end
    
    # Singleton associations can have .find and .new sent to them
    class SingletonResourceServiceProxy < ResourceServiceProxy
      def find(*args)
        if @_controller.find_singleton
          @_controller.instance_eval(&@_controller.find_singleton)
        elsif @_controller.enclosing_resource
          @_controller.enclosing_resource.send(@_controller.resource_source)
        else
          @_controller.resource_class.find(*args)
        end
      end
      
      def new(*args)
        if @_controller.enclosing_resource
          @_controller.enclosing_resource.send("build_#{@_controller.resource_source}", *args)
        else
          @_controller.resource_class.new(*args)
        end
      end
    end
  end
end

# TODO: waiting for http://dev.rubyonrails.org/ticket/8930 to be accepted.  Remove this when it is
#
# This is not a depenency of resources_controller, but it is of the specs.
module ActionController#:nodoc:
  module Routing#:nodoc:
    class RouteSet#:nodoc:
      class NamedRouteCollection#:nodoc:
      private
        def define_url_helper(route, name, kind, options)
          selector = url_helper_name(name, kind)
  
          # The segment keys used for positional paramters
          segment_keys = route.segments.collect do |segment|
            segment.key if segment.respond_to? :key
          end.compact
          hash_access_method = hash_access_name(name, kind)
  
          @module.send :module_eval, <<-end_eval # We use module_eval to avoid leaks
            def #{selector}(*args)
              opts = if args.empty? || Hash === args.first
                args.first || {}
              else
                # allow ordered parameters to be associated with corresponding
                # dynamic segments, so you can do
                #
                #   foo_url(bar, baz, bang)
                #
                # instead of
                #
                #   foo_url(:bar => bar, :baz => baz, :bang => bang)
                #
                # Also allow options hash, so you can do
                #
                #   foo_url(bar, baz, bang, :sort_by => 'baz')
                #
                options = args.last.is_a?(Hash) ? args.pop : {}
                args = args.zip(#{segment_keys.inspect}).inject({}) do |h, (v, k)|
                  h[k] = v
                  h
                end
                options.merge(args)
              end
      
              url_for(#{hash_access_method}(opts))
            end
          end_eval
          @module.send(:protected, selector)
          helpers << selector
        end
      end
    end
  end
end
