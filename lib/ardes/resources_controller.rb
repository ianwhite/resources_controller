module Ardes
  module ResourcesController
    # Specifies that this controller is a REST style controller for the named resource (a resources plural like :users).  You can specify that the 
    # resource is a nested resource.
    #
    # Options:
    # * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    # * <tt>:collection_name:</tt> (if using nested resources - see nested_in) The collection that the resources belongs to, if it can't be inferred from its name
    # * <tt>:route_name:</tt> The name of the route (of the resources, i.e. :users), if it can't be inferred from the name of the controller
    # * <tt>:in:</tt> Ordered array of singular model names which correspond to nesting a resource. 
    #
    # Examples:
    #  resources_controller_for :users
    #  resources_controller_for :users, :class_name => 'Admin::Users'
    #  resources_controller_for :users, :route_name => :admin_users
    #  resources_controller_for :posts, :in => :forum
    #  resources_controller_for :comments, :in => [:forum, :post]
    #
    # === The :in option
    #
    # The default behavior is to set up before filters that load the enclosing resource, and to use associations on that
    # model to find and create the resources.  See nested_in for more details on this, and customising the default behaviour
    #
    def resources_controller_for(resources_name, options = {})
      options.assert_valid_keys(:class_name, :collection_name, :route_name, :in)
      
      self.class_eval do
        unless included_modules.include?(::Ardes::ResourcesController::InstanceMethods)
          class_inheritable_accessor :resources_name, :resource_name, :resource_class, :resource_collection_name, :route_name, :enclosing_resource_names
          self.enclosing_resource_names ||= []
          include InstanceMethods
          include ActionMethods
        end
      end
      
      self.resources_name = resources_name.to_s
      self.resource_name  = self.resources_name.singularize
      self.route_name     = options[:route_name] || controller_name
      self.resource_class = (options[:class_name] || self.resource_name.classify).constantize
      self.resource_collection_name = options[:collection_name]
      
      nested_in(*options[:in]) if options[:in]
    end
    
    # [This can also be called via the <tt>:in</tt> option in <tt>resources_controller_for</tt>]
    #
    # Specifies that the resource is nested in another resource.  Can be called in two ways:
    # * single: <tt>nested_in :resource[, options] [&block]</tt>
    # * multiple: <tt>nested_in :resource1[, :resource2]...</tt>
    #
    # The multiple version is equivalent to calling <tt>nested_in</tt> multiple times, and can only be used to provide the default functionality.
    #
    # Calling <tt>nested_in :foo</tt> will result in the following:
    # * accessor set up for :foo, which gets and sets @foo
    # * a before_filter which sets @foo according to params[:foo_id]
    # * resource_service will change from being the resource class to being @foo.resources association
    #
    # You can customise how the before_filter sets @foo by passing a block:
    #  
    #  resource_controller_for :posts
    #  nested_in :forum {|controller| controller.forum = Forum.find(controller.params[:forum_id])}
    #
    # (The above block just happens to be the default behaviour of nested_in)
    #
    # === Multiple <tt>nested_in</tt>s
    # A typical resource that is multiply nested is found in the following way (example is forum has_many posts, each has_many comments):
    # 
    #  @forum = Forum.find(params[:forum_id])
    #  @post = @forum.posts.fiind(params[:post_id])
    #  @comment = @post.comments.find(params[:id])
    #  @comments = @post.comments.find(:all)
    #
    # The first nesting resource is found from the class, and subsequent ones are found from a collection.  Because of this the first, and subsequent
    # calls to nested_in have different options.
    #
    # First <tt>nested_in</tt> options
    #  * <tt>:class_name:</tt> the name of the class (e.g. 'Forum' in the above example) if it can't be inferred from the name
    #
    # Subsequent <tt>nested_in</tt> options
    #  * <tt>:collection_name:</tt> the name of the collection (e.g. 'posts' in the above example) if it can't be inferred from the name
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
    def nested_in(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}
      raise ArgumentError "when giving more than one nesting, you may not specify options or a block" if names.length > 1 and (block_given? or options.length > 0)
      raise ArgumentError "options should not be given when giving a block" if options.length > 0 and block_given?
      names.each {|name| add_enclosing(name, options, &block)}
    end
      
  private
    def add_enclosing(name, options = {}, &block)
      name = name.to_s
      send "add_#{enclosing_resource_names.size == 0 ? 'first' : 'subsequent'}_enclosing", name, options, &block
      attr_accessor name
      self.enclosing_resource_names << name
    end
  
    def add_first_enclosing(name, options = {}, &block)
      options.assert_valid_keys(:class_name)
      
      class_eval do
        define_method :resource_service do
          @resource_service ||= send(enclosing_resource_names.last).send(resource_collection_name || resources_name)
        end
      end
      
      if block_given?
        before_filter(&block)
      else
        e_class, fk = (options[:class_name] || name.classify).constantize, name.foreign_key
        before_filter {|c| c.send("#{name}=", e_class.find(c.params[fk])) }
      end
    end
    
    def add_subsequent_enclosing(name, options = {}, &block)
      options.assert_valid_keys(:collection_name)
      
      if block_given?
        before_filter(&block)
      else
        prev, coll, fk = enclosing_resource_names.last, options[:collection_name] || name.pluralize, name.foreign_key
        before_filter {|c| c.send("#{name}=", c.send(prev).send(coll).find(c.params[fk]))}
      end
    end
        
    module ActionMethods
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
        self.resource = new_resource(params[resource_name])

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
        @enclosing_resources ||= enclosing_resource_names.inject([]){|m, name| m << send(name)}
      end
      
      # returns the current resource service.  This is used to find and create resources (see find_resource, find_resources, new_resource)
      #
      # For a resource which is not nested this will be the resource class.
      #
      # For a nested resource this will be a has_many association
      def resource_service
        @resource_service ||= resource_class
      end
      
      # sets the current resource service.
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
      def find_resources()
        resource_service.find :all
      end
  
      # finds the resource, using the passed id (default is params[:id])
      def find_resource(id = params[:id])
        resource_service.find id
      end
      
      # makes a new resource, using the passed hash (default is params[resource_name])
      def new_resource(attrs = params[resource_name])
        resource_service.new(attrs)
      end
      
      # returns the url for the passed resource (default is self.resource)
      def resource_url(resource = self.resource)
        send("#{route_name.singularize}_url", *(enclosing_resources + [resource]))
      end
  
      # returns the url for the resources collection
      def resources_url
        send("#{route_name}_url", *enclosing_resources)
      end
    end
  end
end