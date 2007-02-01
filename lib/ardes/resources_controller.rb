module Ardes#:nodoc:
  # This plugin adds easy resource controllers for your RESTful models
  #
  # === Example Usage
  #
  #  class ForumsController < ApplicationController
  #    resources_controller_for :forums
  #  end
  #  
  #  class PostsController < ApplicationController
  #    resources_controller_for :posts, :in => :forum
  #  end
  #  
  #  class CommentsController < ApplicationController
  #    resources_controller_for :comments, :in => [:forum, :post]
  #  end
  #
  # === How it works
  # 
  # A RESTful controller needs to find and create resources.  In the case of a non-nested resource, it uses
  # the resource's class to do this.  In the case of a nested resource, it may use an association to do this.  It so happens
  # that the API for finding and creating resources is exactly the same for classes and has_many associations. which means:
  # 
  # <tt>resource_service</tt> can hold whatever is being used to find or create resources, and can be swapped about to:
  # * ensure that resources can be found and created the same way (DRY)
  # * ensure that only the correct resources are found or created
  #
  # === What you get
  #
  # By including the <tt>resource_controller_for</tt> line the following features are added to the controller:
  #
  # * standard CRUD actions, responding to xml and html (this can be changed with <tt>:actions_include:</tt> option)
  # * compliance with how normal assigns and views works (e.g. PostsController sets a <tt>@posts</tt> instance var in <tt>index</tt>)
  # * accessors +resource+ and +resources+ - which reference the the assigns for the controller (e.g. in Posts controller resource == @post, resources == @posts,  These aid in creating actions shareable in an inhertiance hierachy
  # * a few functions to aid in changing the behaviour of your controller without touching the actions (see InstanceMethods: +find_resource+, +find_resources+, +new_resource+)
  # 
  # if you have a nested resource (by specifying :in or nested_in) you get:
  #
  # * before_filters to assign the nesting resource (@post and @forum in the above examples)
  # * code to ensure that the resource is found, or created, from the correct source (@post.comments for example)
  #
  # === Writing inheritable controllers
  #
  # If you are writing a custom action which is not going be be inherited from, you can write your actions in the usual way, and it will all just work.
  # 
  # Example:
  #  def index
  #    @posts = @forum.find :all
  #    respond_to do |format|
  #      format.xml { render :xml => @posts.to_my_weird_xml } # custom xml handling for some reason
  #    end
  #  end
  #
  # However, if you want to do this for a number of posts controllers (say user's posts, all posts, and a forum's posts) then you can write
  # this action, with it's custom behaviour, once
  #
  # ===== Example
  #  class PostsController < ApplicationController  # all posts
  #    resources_controller_for :posts
  #
  #    def index
  #      self.resources = find_resources
  #      respond_to do |format|
  #        format.xml { render :xml => resources.to_my_weird_xml }
  #      end
  #    end
  #  end
  #
  #  class UserPostsController < PostsController # <= notice inhertiance
  #    nested_in :user
  #  end
  #
  #  class ForumPostsController < PostsController # <= notice inhertiance
  #    nested_in :forum
  #  end
  #
  # Nice and DRY
  #
  #
  # ===== Another example
  # In this example we make use of the [find_resource, find_resources, new_resource] layer to abstract some common funtionality.
  #
  # The example is that of a Signup, and Login (STI classes descending from Event).  All events log the ip address
  # from the request.  We can implement this by modifying how a new resource is created.
  #
  #  class EventsController < ApplicationController
  #    resources_controller_for :events
  #
  #    def new_resource
  #      returning resource_service.new(params[resource_name]) do |event|
  #        event.ip_address = request.remote_ip
  #      end
  #    end
  #  end
  #
  #  class SignupsController < EventsController
  #    resources_controller_for :signups
  #  end
  #
  #  class LoginsController < EventsController
  #    resources_controller_for :logins
  #  end
  #
  # Changing the behaviour of the <tt>new_resource</tt> method allows us to specify behaviour at a more general level, so we don't have to repeat ourselves in actions, which is error prone and boring.
  #
  module ResourcesController
    # Specifies that this controller is a REST style controller for the named resource (a resources plural like :users).  You can specify that the 
    # resource is a nested resource.
    #
    # Options:
    # * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    # * <tt>:collection_name:</tt> (if using nested resources - see nested_in) The collection that the resources belongs to, if it can't be inferred from its name
    # * <tt>:route_name:</tt> The name of the route (of the resources, i.e. :users), if it can't be inferred from the name of the controller
    # * <tt>:in:</tt> Ordered array of singular model names which correspond to nesting a resource.
    # * <tt>:actions_include:</tt> A module, which will be included in the class, default is Ardes::ResourcesController::Actions, if set to false, no actions will be included.
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
    
    # [This can also be called via the <tt>:in</tt> option in <tt>resources_controller_for</tt>]
    #
    # Specifies that the resource is nested in another resource.  Can be called in two ways:
    #
    # single: <tt>nested_in :resource[, options] [&block]
    # 
    # multiple: <tt>nested_in :resource1[, :resource2]...
    #
    # The multiple version is equivalent to calling <tt>nested_in</tt> multiple times, and can only be used to provide the default functionality.
    #
    # Calling <tt>nested_in :foo</tt> will result in the following:
    # * a before_filter which sets @foo according to params[:foo_id]
    # * resource_service will change from being the resource class to being @foo.resources association
    #
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
    #
    # === Multiple <tt>nested_in</tt>s
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
    # First <tt>nested_in</tt> options
    # * <tt>:class_name:</tt> the name of the class (e.g. 'Forum' in the above example) if it can't be inferred from the name
    #
    # Subsequent <tt>nested_in</tt> options
    # * <tt>:collection_name:</tt> the name of the collection (e.g. 'posts' in the above example) if it can't be inferred from the name
    #
    # Example using options (models are in Funky:: module, and collections are name 'the_*'):
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
    # When writing an action that redirects to the list of resources, you may use <tt>resources_url</tt> and the controller
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
        controller.resource_name.humanize
      end
      
      def resources_name
        resource_name.pluralize
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