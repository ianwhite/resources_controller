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
          class_inheritable_accessor  :resources_name, :resource_name, :resource_class, :resource_collection_name
          
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
          include UrlHelpers
          include Actions unless options[:actions_include] == false
          helper Helper
        end
      end

      include options[:actions_include] if options[:actions_include]

      self.resources_name           = resources_name.to_s
      self.resource_name            = self.resources_name.singularize
      self.resource_class           = (options[:class_name] || self.resource_name.classify).constantize
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
        # and alos to allow setting on the instance, without affecting the class attribute
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
      #  @enclosing_resources ||= enclosing_resource_names.inject([]){|m, name| m << instance_variable_get("@#{name}")}.freeze
      end
      
      # returns the current resource service.  This is used to find and create resources (see find_resource, find_resources, new_resource)
      #
      # (By default) For:
      # * a resource which is not nested, this will be the resource class
      # * a nested resource, this will be a collection of the last enclosing resource
      def resource_service
        unless @resource_service
          @resource_service = (enclosing_resources.size == 0) ? resource_class : enclosing_resources.last.send(resource_collection_name || resources_name)
        end
        @resource_service
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
      # finds the collection of resources
      def find_resources
        resource_service.find :all
      end
  
      # finds the resource, using the passed id
      def find_resource
        resource_service.find params[:id]
      end
      
      # makes a new resource, optionally using the passed hash
      def new_resource
        resource_service.new params[resource_name]
      end

      # returns [resources_name, resource_id] sections from the request
      # @TODO - test regexp
      def resources_request
        @resources_request ||= request.env['REQUEST_URI'].scan(%r{/(\w+)/(\d*)})
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
          format.xml  { render :xml => resources.to_xml }
        end
      end

      # GET /events/1
      # GET /events/1.xml
      def show
        self.resource = find_resource

        respond_to do |format|
          format.html # show.rhtml
          format.xml  { render :xml => resource.to_xml }
        end
      end

      # GET /events/new
      def new
        self.resource = new_resource
      end

      # GET /events/1;edit
      def edit
        self.resource = find_resource
      end

      # POST /events
      # POST /events.xml
      def create
        self.resource = new_resource

        respond_to do |format|
          if resource.save
            flash[:notice] = "#{resource_name.humanize} was successfully created."
            format.html { redirect_to resource_url }
            format.xml  { head :created, :location => resource_url }
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => resource.errors.to_xml, :status => 422 }
          end
        end
      end

      # PUT /events/1
      # PUT /events/1.xml
      def update
        self.resource = find_resource
  
        respond_to do |format|
          if resource.update_attributes(params[resource_name])
            flash[:notice] = "#{resource_name.humanize} was successfully updated."
            format.html { redirect_to resource_url }
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.xml  { render :xml => resource.errors.to_xml, :status => 422 }
          end
        end
      end

      # DELETE /events/1
      # DELETE /events/1.xml
      def destroy
        self.resource = find_resource
        resource.destroy
        respond_to do |format|
          flash[:notice] = "#{resource_name} was successfully destroyed."
          format.html { redirect_to resources_url }
          format.xml  { head :ok }
        end
      end
    end
    
    # These methods are provided to aid in writing inheritable controllers.
    #
    # When writing an action that redirects to the list of resources, you may use *resources_url* and the controller
    # will call the url_writer method appropriate to what the controller is a resources controller for.
    module UrlHelpers
      def resource_url(resource = self.resource)
        send("#{name_prefix}#{singular_route_name}_url", *(enclosing_resources + [resource]))
      end
      
      def edit_resource_url(resource = self.resource)
        send("#{name_prefix}edit_#{singular_route_name}_url", *(enclosing_resources + [resource]))
      end
      
      def resources_url
        send("#{name_prefix}#{route_name}_url", *enclosing_resources)
      end
      
      def new_resource_url
        send("#{name_prefix}new_#{singular_route_name}_url", *enclosing_resources)
      end
      
      def resource_path(resource = self.resource)
        send("#{name_prefix}#{singular_route_name}_path", *(enclosing_resources + [resource]))
      end
      
      def edit_resource_path(resource = self.resource)
        send("#{name_prefix}edit_#{singular_route_name}_path", *(enclosing_resources + [resource]))
      end
      
      def resources_path
        send("#{name_prefix}#{route_name}_path", *enclosing_resources)
      end
      
      def new_resource_path
        send("#{name_prefix}new_#{singular_route_name}_path", *enclosing_resources)
      end
    end
    
    # Often it won't be appropriate to re-use views, but
    # sometimes it is.  These helper methods enable reuse by referencing whatever resource the 
    # controller is for.
    #
    # For example:
    #
    # instead of writing:
    #  <% for event in @events %>
    #    <%= link_to 'edit', edit_event_path(event) %>
    #
    # you may write:
    #  <% for event in resources %>
    #    <%= link_to 'edit', edit_resource_path(event) %>
    #
    module Helper
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
      
      def resource_url(resource = nil)
        controller.resource_url(resource)
      end
      
      def edit_resource_url(resource = nil)
        controller.edit_resource_url(resource)
      end
      
      def resources_url
        controller.resources_url
      end
      
      def new_resource_url
        controller.new_resource_url
      end
      
      def resource_path(resource = nil)
        controller.resource_path(resource)
      end
      
      def edit_resource_path(resource = nil)
        controller.edit_resource_path(resource)
      end
      
      def resources_path
        controller.resources_path
      end
      
      def new_resource_path
        controller.new_resource_path
      end
    end
  end
end