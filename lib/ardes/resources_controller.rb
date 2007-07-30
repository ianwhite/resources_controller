module Ardes#:nodoc:
  # With resources_controller (http://svn.ardes.com/rails_plugins/resources_controller) you can quickly add
  # an ActiveResource compliant controller for your your RESTful models.
  # 
  # The intention is not to create an auto-scaffold, although it can be used for that.
  # The intention is to DRY up some of the repetitive code associated with controllers
  # and to facilitate inheritance.
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
    # Specifies that this controller is a REST style controller for the named resource (a resources plural like :users).  You can specify that the 
    # resource is a nested resource.
    #
    # Options:
    # * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    # * <tt>:collection_name:</tt> (if using nested resources - see nested_in) The collection that the resources belongs to, if it can't be inferred from its name
    # * <tt>:route_name:</tt> The name of the route (of the resources, i.e. :users), if it can't be inferred from the name of the controller
    # * <tt>:name_prefix:</tt> The name_prefix of the named route, if it cannot be inferred from the controller heirachy (see nested_in)
    # * <tt>:actions_include:</tt> A module, which will be included in the class, default is Ardes::ResourcesController::Actions, if set to false, no actions will be included.
    # * <tt>:in:</tt> Ordered array of singular model names which correspond to nesting a resource.
    #
    # Examples:
    #  resources_controller_for :users
    #  resources_controller_for :users, :class_name => 'Admin::Users', :actions_include => false
    #  resources_controller_for :users, :route_name => :admin_users, :actions_include => MyOwnActions
    #  resources_controller_for :posts, :in => :forum
    #  resources_controller_for :comments, :in => [:forum, :post]
    #
    # === The :in option
    #
    # The default behavior is to set up before filters that load the enclosing resource, and to use associations on that
    # model to find and create the resources.  See nested_in for more details on this, and customising the default behaviour
    #
    def resources_controller_for(resources_name, options = {})
      options.assert_valid_keys(:class_name, :collection_name, :actions_include, :route_name, :name_prefix, :in)
      
      self.class_eval do
        unless included_modules.include?(::Ardes::ResourcesController::InstanceMethods)
          class_inheritable_reader :route_name, :singular_route_name
          class_inheritable_accessor  :resources_name, :resource_name, :resource_class, :resource_collection_name, :resource_service_class
          
          self.resource_service_class = ResourceService
          
          class<<self
            attr_writer :name_prefix
            
            def name_prefix
              @name_prefix ||= controller_name.sub(route_name, '')
            end
            
            def route_name=(name)
              write_inheritable_attribute(:singular_route_name, name.singularize)
              write_inheritable_attribute(:route_name, name)
            end
          end
          
          include InstanceMethods
          include UrlHelper
          include Actions if options[:actions_include].nil? || options[:actions_include] == true
          helper Helper
        end
      end

      include options[:actions_include] if options[:actions_include]

      self.resources_name           = resources_name.to_s
      self.resource_name            = self.resources_name.singularize
      self.resource_class           = (options[:class_name] || self.resource_name.camelize).constantize
      self.resource_collection_name = options[:collection_name]
      self.route_name               = options[:route_name] || controller_name
      self.name_prefix              = options[:name_prefix]
      
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
    # * <tt>:collection_name:</tt> The collection that the resources belongs to, if it can't be inferred from its name
    # * <tt>:foreign_key:</tt> The foreign key of the resource, if it can;t be inferred from its name
    # * <tt>:anonymous:</tt> set true if the nesting resource type should be inferred from the request
    # * <tt>:polymorphic:</tt> synonym for anonymous
    # * <tt>:load_enclosing:</tt> set true if you want the enclosing resources to be inferred from the request.  This can only be used on the last nested_in.
    # * <tt>:name_prefix:</tt> The name_prefix of the named route, if it cannot be inferred from the controller heirachy (see nested_in).
    #
    # <b>:anonymous and :name_prefix</b> If :anonymous has been set to true the name_prefix will be inferred from the request, pass false to not change the name prefix
    #
    # === Example
    # 
    # Calling <tt>nested_in :foo</tt> will result in the following:
    # * a before_filter which sets @foo according to params[:foo_id] (see load_enclosing_resource)
    # * resource_service will change from being the resource class to being @foo.resources association
    #
    # === customise before_filter
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
    # * Subsequent nested_ins:<tt>:collection_name:</tt> the name of the collection (e.g. 'posts' in the above example) if it can't be inferred from the name
    #
    # === Example using options
    # If you're not using rails conventions that's ok.  Here's an example of how to do it
    # 
    # models are in Funky:: module, and collections are named'the_*':
    #  
    #  class CommentsController < ApplicationController
    #    resources_controller_for :comments, :collection_name => 'the_comments' # @post.the_comments will be used as the resource_service
    #    nested_in :forum, :class_name => 'Funky::Forum'                        # => Funky::Forum will be used to find @forum
    #    nested_in :posts, :collection_name => 'the_posts'                      # => @forum.the_posts will be used to find @post
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
    
  private
    def add_enclosing(name, options = {}, &block)
      options.assert_valid_keys(:polymorphic, :anonymous, :load_enclosing, :class_name, :collection_name, :foreign_key, :name_prefix)
      options[:anonymous] = options[:anonymous] || options[:polymorphic]
      
      before_filter {|controller| controller.send :load_enclosing_resources} if options[:load_enclosing]
      before_filter {|controller| controller.send :load_enclosing_resource, name, options, &block }
    end
    
    module InstanceMethods
      def self.included(base)
        base.send :hide_action, *instance_methods
        
        # the following accessors are set up to use the class attribute as default
        # and also to allow setting on the instance, without affecting the class attribute
        base.class_eval do
          attr_writer :name_prefix
          
          def route_name=(name)
            @singular_route_name = nil
            @route_name = name
          end
          
          def route_name
            @route_name ||= self.class.route_name
          end
          
          def singular_route_name
            @singular_route_name ||= route_name.singularize
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
      
      # returns an array of the controller's enclosing (nested in) resources
      def enclosing_resources
        @enclosing_resources ||= []
      end
      
      # returns the current resource service.  This is used to find and create resources (see ResourceService, and find_resource, find_resources, new_resource)
      def resource_service
        @resource_service ||= resource_service_class.new(self)
      end
      
      # sets the current resource service, which is usually a class, or a has_many association
      #
      # If you wish to provide a customised resource service you need to make sure the object responds
      # appropriately to:
      # * find :all
      # * find id
      # * new
      def resource_service=(service)
        @resource_service = service
      end
      
    protected
      # returns an array containing [resources_name, resource_id] sections from the enclosing request
      def resources_request
        #@resources_request ||= request.path.scan(%r{/(\w+)/(\d*)})
        @resources_request ||= request.path.scan(%r{/(\w+)/([\w\-]*)})
      end

    private
      # load any remaining enclosing resources that nest the current nested_in
      def load_enclosing_resources
        raise RuntimeError, "you can only specify nested_in :load_enclosing => true once" if @_load_enclosing_resources
        @_load_enclosing_resources = true
        
        # ignore the last request pair if it is the resources_name
        enclosing_request = (resources_request.last.first == resources_name) ? resources_request.slice(0..-2) : resources_request
        
        # load the rest of the enclosing resources, except the last (which is loaded by the nested_in
        enclosing_request.slice(enclosing_resources.size..-2).each do |(name, _)|
          load_enclosing_resource(name, :anonymous => true)
        end
      end
    
      def load_enclosing_resource(name, options = {}, &block)
        enclosing_resource = block_given? ? instance_eval(&block) : find_enclosing_resource(name.to_s, options)
        update_name_prefix(options[:name_prefix]) if options[:name_prefix] or (options[:anonymous] && options[:name_prefix] != false)
        enclosing_resources.push(enclosing_resource)
        instance_variable_set("@#{name}", enclosing_resource)
      end
    
      def update_name_prefix(name_prefix)
        name_prefix ||= "#{resources_request[enclosing_resources.size].first.singularize}_"
        self.name_prefix = "#{self.name_prefix}#{name_prefix}"
      end
    
      # This is the default method for finding an enclosing resource, if a block is not given to nested_in
      def find_enclosing_resource(name, options)
        if options[:anonymous]
          source_name, id = *resources_request[enclosing_resources.size]
        else
          source_name, id = options[:class_name] || options[:collection_name] || name, params[options[:foreign_key] || name.foreign_key]
        end
        source = (enclosing_resources.size == 0) ? source_name.classify.constantize : enclosing_resources.last.send(source_name.tableize)
        source.find(id)
      end
    end
    
    # standard CRUD actions, with html and xml responses, re-written to mnake best use of resource_cotroller.
    # This helps if you're writing controllers that you want to share via mixin or inheritance.
    #
    # The idea is to decouple the <b>model name</b> from the action code.
    #
    # Here's how:
    #
    # === finding and making new resources
    # Instead of this:
    #   @post = Post.find(params[:id])
    #   @post = Post.new
    #   @posts = Post.find(:all)
    #
    # do this:
    #   self.resource = find_resource
    #   self.resource = new_resource
    #   self.resources = find_resources
    #
    # === referring to resources
    # Instead of this:
    #   format.xml { render :xml => @post.to_xml }
    #   format.xml { render :xml => @posts.to_xml }
    #   
    # do this:
    #   format.xml { render :xml => resource.to_xml }
    #   format.xml { render :xml => resources.to_xml }
    #
    # === urls 
    # Instead of this:
    #   redirect_to posts_url
    #   redirect_to new_post_url
    #
    # do this:
    #   redirect_to resources_url
    #   redirect_to new_resource_url
    #
    module Actions
      # GET /events
      # GET /events.xml
      def index
        self.resources = find_resources
    
        respond_to do |format|
          format.html # index.rhtml
          format.js
          format.xml  { render :xml => resources.to_xml }
        end
      end

      # GET /events/1
      # GET /events/1.xml
      def show
        self.resource = find_resource

        respond_to do |format|
          format.html # show.rhtml
          format.js
          format.xml  { render :xml => resource.to_xml }
        end
      end

      # GET /events/new
      def new
        self.resource = new_resource
      end

      # GET /events/1/edit
      def edit
        self.resource = find_resource
      end

      # POST /events
      # POST /events.xml
      def create
        self.resource = new_resource

        respond_to do |format|
          if resource.save
            format.html do
              flash[:notice] = "#{resource_name.humanize} was successfully created."
              redirect_to resource_url
            end
            format.js
            format.xml  { head :created, :location => resource_url }
          else
            format.html { render :action => "new" }
            format.js
            format.xml  { render :xml => resource.errors.to_xml, :status => :unprocessable_entity }
          end
        end
      end

      # PUT /events/1
      # PUT /events/1.xml
      def update
        self.resource = find_resource
  
        respond_to do |format|
          if resource.update_attributes(params[resource_name])
            format.html do
              flash[:notice] = "#{resource_name.humanize} was successfully updated."
              redirect_to resource_url
            end
            format.js
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.js
            format.xml  { render :xml => resource.errors.to_xml, :status => :unprocessable_entity }
          end
        end
      end

      # DELETE /events/1
      # DELETE /events/1.xml
      def destroy
        self.resource = find_resource
        resource.destroy
        respond_to do |format|
          format.html do
            flash[:notice] = "#{resource_name.humanize} was successfully destroyed."
            redirect_to resources_url
          end
          format.js
          format.xml  { head :ok }
        end
      end
    end
    
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
        if resource_url_helper_method?(method) 
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
      def resource_url_helper_method?(resource_method)
        if resource_method.to_s =~ /_(path|url)$/ && resource_method.to_s =~ /(^|^.*_)resource(s)?_/
          route, route_method = *route_and_method_from_resource_method_and_name_prefix(resource_method, name_prefix)
          respond_to_without_url_helper?(route_method)
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
        self.class.send :module_eval, <<-end_eval
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
        
        self.class.send :module_eval, <<-end_eval
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
      
      # delegate url helper method to the controller
      def method_missing_with_url_helper(method, *args, &block)
        # TODO: test that methods are only defined once
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
  
  # use this class to extend or modify the behaviour of the resource_service
  #
  # If using your own ResourceService then you should tell your controller by
  # setting self.resource_service_class
  #
  #   class FoosController < ApplicationController
  #     resources_controller_for :foos
  #     self.resource_service_class = FoosResourceService
  #   end
  #
  # Alternatively, if you're doing something really wacky, you can set resource_service
  # on the controller instance. (to an instance of the class)
  #
  #   before_filter {|controller| controller.resource_service = FoosResourceService.new(:with, :my, :wacky, :args)}
  #
  class ResourceService
    attr_reader :controller, :service
    
    # When the resource service is created, the default service is either the resource_class (in the case
    # when there are no enclosing resources) or the collection of the last enclosing resource (when there are enclosing
    # resources)
    def initialize(controller)
      @controller = controller
      if controller.enclosing_resources.size == 0
        @service = controller.resource_class
      else
        @service = controller.enclosing_resources.last.send(controller.resource_collection_name || controller.resources_name)
      end
    end
    
    def new(*args)
      @service.new(*args)
    end
      
    def find(*args)
      @service.find(*args)
    end
    
    def method_missing(method, *args, &block)
      @service.send(method, *args, &block)
    end
  end
end

# TODO: waiting for http://dev.rubyonrails.org/ticket/8930 to be accepted.  Remove this when it is
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

