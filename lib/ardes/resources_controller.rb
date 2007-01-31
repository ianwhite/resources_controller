module Ardes
  module RestController
    # Specifies that this controller is a REST style controller for the named resource (a collection - like :users)
    #
    #  * <tt>:class_name:</tt> The class name of the resource, if it can't be inferred from its name
    #  * <tt>:route_name:</tt> The name of the route (of the collection, i.e. :users), if it can't be inferred from the name of the controller
    #  * <tt>:enclosed_by:</tt> Ordered array of singular model names, or array pair when the finder needs to be specified
    #    * [for the first enclosing only] The class name, if it can't be inferred
    #    * [for any subsequent enclosings] The collection name used on the previous enclosing, if it can't be inferred
    #
    # Example
    #
    #  for_resources :users
    #  for_resources :users, :class_name => 'Admin::Users'
    #  for_resources :users, :route_name => :admin_users
    #
    #  for_resources :posts, :enclosed_by => :forum
    #  for_resources :posts, :enclosed_by => [:user, :forum]
    #
    #  for_resources :posts, :enclosed_by => [[:user, 'Admin::User'], :forum]
    #  for_resources :posts, :enclosed_by => [[:user, 'Admin::User'], [:forum, :my_forums]]
    #
    def resources_controller_for(collection_name, options = {})
      options.assert_valid_keys(:class_name, :route_name, :in)
      
      self.class_eval do
        unless included_modules.include?(::Ardes::RestController::InstanceMethods)
          class_inheritable_accessor :collection_name, :element_name, :element_class, :route_name, :enclosing_names
          self.enclosing_names ||= []
          include InstanceMethods
          include ActionMethods
        end
      end
      
      self.collection_name = collection_name.to_s
      self.element_name    = self.collection_name.singularize
      self.route_name      = options[:route_name] || controller_name
      self.element_class   = (options[:class_name] || self.element_name.classify).constantize
      
      nested_in(*options[:in]) if options[:in]
    end
    
    def nested_in(*names, &block)
      options = names.last.is_a?(Hash) ? names.pop : {}
      raise ArgumentError "when giving more than one nesting, you may not specify options or a block" if names.length > 1 and (block_given? or options.length > 0)
      raise ArgumentError "options should not be given when giving a block" if options.length > 0 and block_given?
      names.each {|name| add_enclosing(name, options, &block)}
    end
      
  private
    def add_enclosing(name, options = {}, &block)
      name = name.to_s
      send "add_#{enclosing_names.size == 0 ? 'first' : 'subsequent'}_enclosing", name, options, &block
      attr_accessor name
      self.enclosing_names << name
    end
  
    def add_first_enclosing(name, options = {}, &block)
      options.assert_valid_keys(:class_name)
      
      class_eval do
        define_method :resource_service do
          @resource_service ||= send(enclosing_names.last).send(collection_name)
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
        prev, coll, fk = enclosing_names.last, options[:collection_name] || name.pluralize, name.foreign_key
        before_filter {|c| c.send("#{name}=", c.send(prev).send(coll).find(c.params[fk]))}
      end
    end
        
    module ActionMethods
      # GET /events
      # GET /events.xml
      def index
        self.collection = find_collection
    
        respond_to do |format|
          format.html # index.rhtml
          format.xml  { render :xml => collection.to_xml }
        end
      end

      # GET /events/1
      # GET /events/1.xml
      def show
        self.element = find_element

        respond_to do |format|
          format.html # show.rhtml
          format.xml  { render :xml => element.to_xml }
        end
      end

      # GET /events/new
      def new
        self.element = new_element
      end

      # GET /events/1;edit
      def edit
        self.element = find_element
      end

      # POST /events
      # POST /events.xml
      def create
        self.element = new_element(params[element_name])

        respond_to do |format|
          if element.save
            flash[:notice] = "#{element_name.humanize} was successfully created."
            format.html { redirect_to element_url }
            format.xml  { head :created, :location => element_url }
          else
            format.html { render :action => "new" }
            format.xml  { render :xml => element.errors.to_xml, :status => 422 }
          end
        end
      end

      # PUT /events/1
      # PUT /events/1.xml
      def update
        self.element = find_element
  
        respond_to do |format|
          if element.update_attributes(params[element_name])
            flash[:notice] = "#{element_name.humanize} was successfully updated."
            format.html { redirect_to element_url }
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.xml  { render :xml => element.errors.to_xml, :status => 422 }
          end
        end
      end

      # DELETE /events/1
      # DELETE /events/1.xml
      def destroy
        self.element = find_element
        element.destroy
        respond_to do |format|
          flash[:notice] = "#{element_name} was successfully destroyed."
          format.html { redirect_to collection_url }
          format.xml  { head :ok }
        end
      end
    end
  
    module InstanceMethods
      def self.included(base)
        base.send :hide_action, *instance_methods
      end
      
      def element
        instance_variable_get("@#{element_name}")
      end
      
      def element=(elem)
        instance_variable_set("@#{element_name}", elem)
      end
  
      def collection
        instance_variable_get("@#{collection_name}")
      end
      
      def collection=(coll)
        instance_variable_set("@#{collection_name}", coll)
      end
      
      def enclosing_elements
        @enclosing_elements ||= enclosing_names.inject([]){|m, name| m << send(name)}
      end
      
      def resource_service
        @resource_service ||= element_class
      end
      
      def resource_service=(service)
        @resource_service = service
      end
      
    protected  
      def find_collection()
        resource_service.find :all
      end
  
      def find_element(id = params[:id])
        resource_service.find id
      end
      
      def new_element(attrs = params[element_name])
        resource_service.new(attrs)
      end
      
      def element_url
        send("#{route_name.singularize}_url", *(enclosing_elements + [element]))
      end
  
      def collection_url
        send("#{route_name}_url", *enclosing_elements)
      end
    end
  end
end