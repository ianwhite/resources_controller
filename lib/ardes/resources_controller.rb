module Ardes#:nodoc:
  # With {resources_controller}[link:http://svn.ardes.com/rails_plugins/resources_controller] you can quickly add
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
      options.assert_valid_keys(:class_name, :collection_name, :actions_include, :route_name, :in)
      
      self.class_eval do
        unless included_modules.include?(::Ardes::ResourcesController::InstanceMethods)
          class_inheritable_accessor  :resources_name, :resource_name, :resource_class, :resource_collection_name, :route_name, :singular_route_name, :enclosing_resource_names
          self.enclosing_resource_names ||= []
          include InstanceMethods
          include UrlHelpers
          include Actions unless options[:actions_include] == false
          helper Helper
        end
        include options[:actions_include] if options[:actions_include]
      end

      self.resources_name           = resources_name.to_s
      self.resource_name            = self.resources_name.singularize
      self.route_name               = options[:route_name] || controller_name
      self.singular_route_name      = self.route_name.singularize
      self.resource_class           = (options[:class_name] || self.resource_name.classify).constantize
      self.resource_collection_name = options[:collection_name]
      
      nested_in(*options[:in]) if options[:in]
    end
    
    # Specifies that the resource is nested in another resource.  Can be called in two ways:
    #
    #   nested_in :resource[, options] [&block]
    #   nested_in :resource1[, :resource2]...
    #
    # The latter version is equivalent to calling <tt>nested_in</tt> multiple times, and can only be used to provide the default functionality.
    #
    # Calling <tt>nested_in :foo</tt> will result in the following:
    # * a before_filter which sets @foo according to params[:foo_id]
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
      raise ArgumentError "options should not be given when giving a block" if options.length > 0 and block_given?
      names.each {|name| add_enclosing(name, options, &block)}
    end
    
  private
    def add_enclosing(name, options = {}, &block)
      name = name.to_s
      is_first = enclosing_resource_names.size == 0
      is_first ? options.assert_valid_keys(:class_name) : options.assert_valid_keys(:collection_name)
      if block_given?
        before_filter {|c| c.instance_variable_set("@#{name}", c.instance_eval(&block)) }
      else
        if is_first
          e_class, fk = (options[:class_name] || name.classify).constantize, name.foreign_key
          before_filter {|c| c.instance_eval "@#{name} = #{e_class}.find(params[:#{fk}])"}
        else
          prev, coll, fk = enclosing_resource_names.last, options[:collection_name] || name.pluralize, name.foreign_key
          before_filter {|c| c.instance_eval "@#{name} = @#{prev}.#{coll}.find(params[:#{fk}])"}
        end
      end
      self.enclosing_resource_names << name
    end

    # These methods are provided to aid in writing inheritable controllers.
    #
    # When writing an action that redirects to the list of resources, you may use *resources_url* and the controller
    # will call the url_writer method appropriate to what the controller is a resources controller for.
    module UrlHelpers
      def resource_url(resource = self.resource)
        send("#{singular_route_name}_url", *(enclosing_resources + [resource]))
      end
      
      def edit_resource_url(resource = self.resource)
        send("edit_#{singular_route_name}_url", *(enclosing_resources + [resource]))
      end
      
      def resources_url
        send("#{route_name}_url", *enclosing_resources)
      end
      
      def new_resource_url
        send("new_#{singular_route_name}_url", *enclosing_resources)
      end
      
      def resource_path(resource = self.resource)
        send("#{singular_route_name}_path", *(enclosing_resources + [resource]))
      end
      
      def edit_resource_path(resource = self.resource)
        send("edit_#{singular_route_name}_path", *(enclosing_resources + [resource]))
      end
      
      def resources_path
        send("#{route_name}_path", *enclosing_resources)
      end
      
      def new_resource_path
        send("new_#{singular_route_name}_path", *enclosing_resources)
      end
    end
    
    module InstanceMethods
      def self.included(base)
        base.send :hide_action, *instance_methods
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
        @enclosing_resources ||= enclosing_resource_names.inject([]){|m, name| m << instance_variable_get("@#{name}")}
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