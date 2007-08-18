module Ardes#:nodoc:
  module ResourcesController
    module SingletonActions
      # GET /event
      # GET /event
      def show
        self.resource = find_resource

        respond_to do |format|
          format.html # show.rhtml
          format.js
          format.xml  { render :xml => resource.to_xml }
        end
      end

      # GET /event/new
      def new
        self.resource = new_resource
      end

      # GET /event/edit
      def edit
        self.resource = find_resource
      end

      # POST /event
      # POST /event.xml
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

      # PUT /event
      # PUT /event.xml
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

      # DELETE /event
      # DELETE /event.xml
      def destroy
        self.resource = find_resource
        resource.destroy
        respond_to do |format|
          format.html do
            flash[:notice] = "#{resource_name.humanize} was successfully destroyed."
            redirect_to enclosing_resource_url if enclosing_resource
          end
          format.js
          format.xml  { head :ok }
        end
      end
    end
  end
end