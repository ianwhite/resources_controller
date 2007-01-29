module Ardes
  module RestController
    def rest_controller_for(collection_name, options = {})
      self.class_eval do
        unless included_modules.include?(::Ardes::RestController::InstanceMethods)
          class_inheritable_accessor :collection_name, :element_class, :element_name
          include InstanceMethods
        end
      
        self.collection_name = collection_name
        self.element_name    = collection_name.to_s.singularize
        self.element_class   = options[:class] || element_name.classify.constantize
      end
    end
    
    module InstanceMethods
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
  
      def element; instance_variable_get("@#{element_name}"); end
      def element=(elem); instance_variable_set("@#{element_name}", elem); end
  
      def collection; instance_variable_get("@#{collection_name}"); end
      def collection=(coll); instance_variable_set("@#{collection_name}", coll); end

    protected  
      def find_collection
        element_class.find :all
      end
  
      def find_element(id = params[:id])
        element_class.find id
      end
      
      def new_element(attrs = params[element_name])
        element_class.new(attrs)
      end
      
      def element_url
        send("#{element_name}_url", element)
      end
  
      def collection_url
        send("#{collection_name}_url")
      end
    end
  end
end