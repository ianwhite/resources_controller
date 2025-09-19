module ResourcesController
  # standard CRUD actions, with html and json responses, re-written to mnake best use of resources_cotroller.
  # This helps if you're writing controllers that you want to share via mixin or inheritance.
  #
  # This module is used as the actions for the controller by default, but you can change this behaviour:
  #  
  #   resources_controller_for :foos, :actions_include => false               # don't include any actions
  #   resources_controller_for :foos, :actions_include => Some::Other::Module # use this module instead
  #
  # == Why?
  #
  # The idea is to decouple the <b>model name</b> from the action code.
  #
  # Here's how:
  #
  # === finding and making new resources
  # Instead of this:
  #   @post = Post.find(params[:id])
  #   @post = Post.new
  #   @posts = Post.all
  #
  # do this:
  #   self.resource = find_resource
  #   self.resource = new_resource
  #   self.resources = find_resources
  #
  # === referring to resources
  # Instead of this:
  #   format.json { render :json => @post }
  #   format.json { render :json => @posts }
  #   
  # do this:
  #   format.json { render :json => resource }
  #   format.json { render :json => resources }
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
  # == strong parameters
  #
  # Never trust parameters from the scary internet. Create your own white list method called 
  #   resource_params
  # or, even better, a method named after your resource name, e.g. 
  #   event_params
  #
  module Actions

    # GET /events
    # GET /events.json
    def index
      self.resources = find_resources
    end

    # GET /events/1
    # GET /events/1.json
    def show
      self.resource = find_resource
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
    # POST /events.json
    def create
      self.resource = new_resource( resource_params )
      
      respond_to do |format|
        if resource.save
          format.html { redirect_to resource_url, notice: "#{resource_name.humanize} was successfully created." }
          format.js
          format.json { render :show, status: :create, location: resource_url }
        else
          format.html { render :new }
          format.js   { render :new }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /events/1
    # PATCH/PUT /events/1.json
    def update
      self.resource = find_resource
      
      respond_to do |format|
        if resource.update( resource_params )
          format.html { redirect_to resource_url, notice: "#{resource_name.humanize} was successfully updated." }
          format.js
          format.json { render :show, status: :ok, location: resource_url }
        else
          format.html { render :edit }
          format.js   { render :edit }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /events/1
    # DELETE /events/1.json
    def destroy
      self.resource = destroy_resource
      respond_to do |format|
        format.html { redirect_to resources_url, notice: "#{resource_name.humanize} was successfully destroyed." }
        format.js
        format.json { head :no_content }
      end
    end
  end

end
