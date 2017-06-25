module ResourcesController
  module SingletonActions
    include Actions
    
    undef index

    # DELETE /event
    # DELETE /event.json
    def destroy
      self.resource = destroy_resource
      respond_to do |format|
        format.html { 
          redirect_to enclosing_resource_url if enclosing_resource
          flash[:notice] = "#{resource_name.humanize} was successfully destroyed."
        }
        format.json { head :no_content }
      end
    end
  end
end
