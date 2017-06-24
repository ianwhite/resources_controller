require 'spec_helper'

describe ForumsController do
  describe "Routing shortcuts for Forums should map" do
  
    before(:each) do
      @forum = double('Forum')
      allow(@forum).to receive(:to_param).and_return('2')
      allow(Forum).to receive(:find).and_return(@forum)
      get :show, params: { :id => "2" }
    end
  
    it "resources_path to /forums" do
      expect(controller.resources_path).to eq('/forums')
    end

    it "resources_path(:foo => 'bar') to /forums?foo=bar" do
      expect(controller.resources_path(:foo => 'bar')).to eq('/forums?foo=bar')
    end

    it "resource_path to /forums/2" do
      expect(controller.resource_path).to eq('/forums/2')
    end

    it "resource_path(:foo => 'bar') to /forums/2?foo=bar" do
      expect(controller.resource_path(:foo => 'bar')).to eq('/forums/2?foo=bar')
    end
  
    it "resource_path(9) to /forums/9" do
      expect(controller.resource_path(9)).to eq('/forums/9')
    end

    it "resource_path(9, :foo => 'bar') to /forums/2?foo=bar" do
      expect(controller.resource_path(9, :foo => 'bar')).to eq('/forums/9?foo=bar')
    end

    it "edit_resource_path to /forums/2/edit" do
      expect(controller.edit_resource_path).to eq('/forums/2/edit')
    end
  
    it "edit_resource_path(9) to /forums/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/9/edit')
    end
  
    it "new_resource_path to /forums/new" do
      expect(controller.new_resource_path).to eq('/forums/new')
    end
  
    it "resources_url to http://test.host/forums" do
      expect(controller.resources_url).to eq('http://test.host/forums')
    end

    it "resource_url to http://test.host/forums/2" do
      expect(controller.resource_url).to eq('http://test.host/forums/2')
    end
  
    it "resource_url(9) to http://test.host/forums/9" do
      expect(controller.resource_url(9)).to eq('http://test.host/forums/9')
    end

    it "edit_resource_url to http://test.host/forums/2/edit" do
      expect(controller.edit_resource_url).to eq('http://test.host/forums/2/edit')
    end
  
    it "edit_resource_url(9) to http://test.host/forums/9/edit" do
      expect(controller.edit_resource_url(9)).to eq('http://test.host/forums/9/edit')
    end
  
    it "new_resource_url to http://test.host/forums/new" do
      expect(controller.new_resource_url).to eq('http://test.host/forums/new')
    end
 
    it "resource_interests_path to /forums/2/interests" do
      expect(controller.resource_interests_path).to eq("/forums/2/interests")
    end
  
    it "resource_interests_path(:foo => 'bar') to /forums/2/interests?foo=bar" do
      expect(controller.resource_interests_path(:foo => 'bar')).to eq('/forums/2/interests?foo=bar')
    end
  
    it "resource_interests_path(9) to /forums/9/interests" do
      expect(controller.resource_interests_path(9)).to eq("/forums/9/interests")
    end
  
    it "resource_interests_path(9, :foo => 'bar') to /forums/9/interests?foo=bar" do
      expect(controller.resource_interests_path(9, :foo => 'bar')).to eq("/forums/9/interests?foo=bar")
    end

    it "resource_interest_path(5) to /forums/2/interests/5" do
      expect(controller.resource_interest_path(5)).to eq("/forums/2/interests/5")
    end
  
    it "resource_interest_path(9,5) to /forums/9/interests/5" do
      expect(controller.resource_interest_path(9,5)).to eq("/forums/9/interests/5")
    end
  
    it "resource_interest_path(9,5, :foo => 'bar') to /forums/9/interests/5?foo=bar" do
      expect(controller.resource_interest_path(9, 5, :foo => 'bar')).to eq("/forums/9/interests/5?foo=bar")
    end

    it 'new_resource_interest_path(9) to /forums/9/interests/new' do
      expect(controller.new_resource_interest_path(9)).to eq("/forums/9/interests/new")
    end
  
    it 'edit_resource_interest_path(5) to /forums/2/interests/5/edit' do
      expect(controller.edit_resource_interest_path(5)).to eq("/forums/2/interests/5/edit")
    end
  
    it 'edit_resource_interest_path(9,5) to /forums/9/interests/5/edit' do
      expect(controller.edit_resource_interest_path(9,5)).to eq("/forums/9/interests/5/edit")
    end
  
    it "respond_to?(:edit_resource_interest_path) should == true" do
      expect(controller).to respond_to(:edit_resource_interest_path)
    end

    it "resource_users_path should raise informative NoMethodError" do
      expect{ controller.resource_users_path }.to raise_error(ResourcesController::CantMapRoute, <<-end_str
Tried to map :resource_users_path to :forum_users_path,
which doesn't exist. You may not have defined the route in config/routes.rb.

Or, if you have unconventianal route names or name prefixes, you may need
to explicictly set the :route option in resources_controller_for, and set
the :name_prefix option on your enclosing resources.

Currently:
:route is 'forum'
generated name_prefix is ''
end_str
      )
    end
  
    it "enclosing_resource_path should raise informative NoMethodError" do
      expect{ controller.enclosing_resource_path }.to raise_error(NoMethodError, "Tried to map :enclosing_resource_path but there is no enclosing_resource for this controller")
    end
  
    it "any_old_missing_method should raise NoMethodError" do
      expect{ controller.any_old_missing_method }.to raise_error(NoMethodError)
    end
  
    it "respond_to?(:resource_users_path) should == false" do
      expect(controller).not_to respond_to(:resource_users_path)
    end
  end

  describe ForumsController, " (checking that non actions are hidden)" do
    #pending "use private methods / less important with modern rails routing"
    #it "should only have CRUD actions as action_methods" do
    #  (@controller.class.send(:action_methods) & Set.new(['resource', 'resources'])).should be_empty
    #end
  end

  describe ForumsController, " requesting garbage url" do
    it "should raise ResourcesController::Specification::NoClassFoundError" do
      expect { get :index, params: { :resource_path => "/forums/\ncrayzeee" } }.to raise_error(ResourcesController::Specification::NoClassFoundError)
    end
  end

  describe ForumsController, " requesting / (testing resource_path)" do
    it "should route to { :controller => 'forums', :action => 'index', :resource_path => '/forums' } from GET /" do
      expect({:get => "/"}).to route_to(:controller => 'forums', :action => 'index', :resource_path => '/forums')
    end
  
    before(:each) do
      @mock_forums = double('forums')
      allow(Forum).to receive(:all).and_return(@mock_forums)
    end
  
    def do_get
      get :index, params: { :resource_path => '/forums' }
    end
  
    it "should be successful" do
      do_get
      expect(response).to be_success
    end

    it "should render index.rhtml" do
      do_get
      expect(response).to render_template(:index)
    end
  
    it "should find all forums" do
      expect(Forum).to receive(:all).and_return(@mock_forums)
      do_get
    end
  
    it "should assign the found forums for the view" do
      do_get
      expect(assigns[:forums]).to eq(@mock_forums)
    end
  end

  describe ForumsController, " requesting /create_forum (testing resource_method)" do
    it "should generate params { :controller => 'forums', :action => 'create', :resource_path => '/forums', :resource_method => :post } from GET /create_forum" do
      expect({:get => "/create_forum"}).to route_to(:controller => 'forums', :action => 'create', :resource_path => '/forums', :resource_method => :post)
    end
  
    before(:each) do
      @mock_forum = double('Forum')
      allow(@mock_forum).to receive(:save).and_return(true)
      allow(@mock_forum).to receive(:to_param).and_return("1")
      allow(Forum).to receive(:new).and_return(@mock_forum)
    end
  
    def do_post
      post :create, params: { :forum => {:name => 'Forum'}, :resource_path => '/forums', :resource_method => :post }
    
    end
  
    it "should create a new forum" do
      expect(Forum).to receive(:new).with({'name' => 'Forum'}).and_return(@mock_forum)
      do_post
    end

    it "should set the flash notice" do
      do_post
      expect(flash[:notice]).to eq("Forum was successfully created.")
    end

    it "should redirect to the new forum" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/1")
    end
  end

  describe "Requesting /forums using GET" do

    before(:each) do
      @mock_forums = double('forums')
      allow(Forum).to receive(:all).and_return(@mock_forums)
    end
  
    def do_get
      get :index
    end
  
    it "should be successful" do
      do_get
      expect(response).to be_success
    end

    it "should render index.rhtml" do
      do_get
      expect(response).to render_template(:index)
    end
  
    it "should find all forums" do
      expect(Forum).to receive(:all).and_return(@mock_forums)
      do_get
    end
  
    it "should assign the found forums for the view" do
      do_get
      expect(assigns[:forums]).to eq(@mock_forums)
    end
  end

  describe "Requesting /forums.xml using GET" do

    before(:each) do
      @mock_forums = double('forums')
      allow(@mock_forums).to receive(:to_xml).and_return("XML")
      allow(Forum).to receive(:all).and_return(@mock_forums)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :index
    end
  
    it "should be successful" do
      do_get
      expect(response).to be_success
    end

    it "should find all forums" do
      expect(Forum).to receive(:all).and_return(@mock_forums)
      do_get
    end
  
    it "should render the found forums as xml" do
      expect(@mock_forums).to receive(:to_xml).and_return("XML")
      do_get
      expect(response.body).to eql("XML")
    end
  end

  describe "Requesting /forums using XHR GET" do

    before(:each) do
      @mock_forums = double('forums')
      allow(Forum).to receive(:all).and_return(@mock_forums)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "text/javascript"
      get :index, xhr: true
    end
  
    it "should be successful" do
      do_get
      expect(response).to be_success
    end

    it "should find all forums" do
      expect(Forum).to receive(:all).and_return(@mock_forums)
      do_get
    end
  
    it "should render index.rjs" do
      do_get
      expect(response).to render_template('index')
    end
  end

  describe "Requesting /forums/1 using GET" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_get
      get :show, params: { :id => "1" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render show.rhtml" do
      do_get
      expect(response).to render_template(:show)
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_get
    end
  
    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@mock_forum)
    end
  end

  describe "Requesting /forums/1.xml using GET" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(@mock_forum).to receive(:to_xml).and_return("XML")
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_get
      @request.env["HTTP_ACCEPT"] = "application/xml"
      get :show, params: { :id => "1" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_get
    end
  
    it "should render the found forum as xml" do
      expect(@mock_forum).to receive(:to_xml).and_return("XML")
      do_get
      expect(response.body).to eql("XML")
    end
  end

  describe "Requesting /forums/1 using XHR GET" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_get
      get :show, params: { :id => "1" }, xhr: true
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render show.rjs" do
      do_get
      expect(response).to render_template('show')
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_get
    end
  
    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@mock_forum)
    end
  end

  describe "Requesting /forums/new using GET" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(Forum).to receive(:new).and_return(@mock_forum)
    end
  
    def do_get
      get :new
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render new.rhtml" do
      do_get
      expect(response).to render_template(:new)
    end
  
    it "should create an new forum" do
      expect(Forum).to receive(:new).and_return(@mock_forum)
      do_get
    end
  
    it "should not save the new forum" do
      expect(@mock_forum).not_to receive(:save)
      do_get
    end
  
    it "should assign the new forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@mock_forum)
    end
  end

  describe "Requesting /forums/1/edit using GET" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_get
      get :edit, params: { :id => "1" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render edit.rhtml" do
      do_get
      expect(response).to render_template(:edit)
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).and_return(@mock_forum)
      do_get
    end
  
    it "should assign the found Forum for the view" do
      do_get
      expect(assigns(:forum)).to equal(@mock_forum)
    end
  end

  describe "Requesting /forums using POST" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(@mock_forum).to receive(:save).and_return(true)
      allow(@mock_forum).to receive(:to_param).and_return("1")
      allow(Forum).to receive(:new).and_return(@mock_forum)
    end
  
    def do_post
      post :create, params: { :forum => {:name => 'Forum'} }
    end
  
    it "should create a new forum" do
      expect(Forum).to receive(:new).with({'name' => 'Forum'}).and_return(@mock_forum)
      do_post
    end

    it "should set the flash notice" do
      do_post
      expect(flash[:notice]).to eq("Forum was successfully created.")
    end

    it "should redirect to the new forum" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/1")
    end
  end

  describe "Requesting /forums using XHR POST" do

    before(:each) do
      @mock_forum = double('Forum')
      allow(@mock_forum).to receive(:save).and_return(true)
      allow(@mock_forum).to receive(:to_param).and_return("1")
      allow(Forum).to receive(:new).and_return(@mock_forum)
    end
  
    def do_post
      post :create, params: { :forum => {:name => 'Forum'} }, xhr: true
    end
  
    it "should create a new forum" do
      expect(Forum).to receive(:new).with({'name' => 'Forum'}).and_return(@mock_forum)
      do_post
    end

    it "should not set the flash notice" do
      do_post
      expect(flash[:notice]).to eq(nil)
    end

    it "should render create.rjs" do
      do_post
      expect(response).to render_template('create')
    end
  
    it "should render new.rjs if unsuccesful" do
      allow(@mock_forum).to receive(:save).and_return(false)
      do_post
      expect(response).to render_template('new')
    end
  end

  describe "Requesting /forums/1 using PUT" do

    before(:each) do
      @mock_forum = double('Forum').as_null_object
      allow(@mock_forum).to receive(:to_param).and_return("1")
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_update
      put :update, params: { :id => "1" }
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_update
    end

    it "should set the flash notice" do
      do_update
      expect(flash[:notice]).to eq("Forum was successfully updated.")
    end

    it "should update the found forum" do
      expect(@mock_forum).to receive(:update_attributes)
      do_update
      expect(assigns(:forum)).to eq(@mock_forum)
    end

    it "should assign the found forum for the view" do
      do_update
      expect(assigns(:forum)).to eq(@mock_forum)
    end

    it "should redirect to the forum" do
      do_update
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/1")
    end
  end

  describe "Requesting /forums/1 using XHR PUT" do

    before(:each) do
      @mock_forum = double('Forum').as_null_object
      allow(@mock_forum).to receive(:to_param).and_return("1")
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_update
      put :update, params: { :id => "1" }, xhr: true
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_update
    end

    it "should update the found forum" do
      expect(@mock_forum).to receive(:update_attributes)
      do_update
      expect(assigns(:forum)).to eq(@mock_forum)
    end

    it "should not set the flash notice" do
      do_update
      expect(flash[:notice]).to eq(nil)
    end

    it "should assign the found forum for the view" do
      do_update
      expect(assigns(:forum)).to eq(@mock_forum)
    end

    it "should render update.rjs" do
      do_update
      expect(response).to render_template('update')
    end
  
    it "should render edit.rjs, on unsuccessful save" do
      allow(@mock_forum).to receive(:update_attributes).and_return(false)
      do_update
      expect(response).to render_template('edit')
    end
  end

  describe "Requesting /forums/1 using DELETE" do

    before(:each) do
      @mock_forum = double('Forum').as_null_object
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_delete
      delete :destroy, params: { :id => "1" }
    end

    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_delete
    end
  
    it "should call destroy on the found forum" do
      expect(@mock_forum).to receive(:destroy)
      do_delete
    end
  
    it "should set the flash notice" do
      do_delete
      expect(flash[:notice]).to eq('Forum was successfully destroyed.')
    end
  
    it "should redirect to the forums list" do
      do_delete
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums")
    end
  end

  describe "Requesting /forums/1 using XHR DELETE" do

    before(:each) do
      @mock_forum = double('Forum').as_null_object
      allow(Forum).to receive(:find).and_return(@mock_forum)
    end
  
    def do_delete
      delete :destroy, params: { :id => "1" }, xhr: true
    end

    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("1").and_return(@mock_forum)
      do_delete
    end
  
    it "should not set the flash notice" do
      do_delete
      expect(flash[:notice]).to eq(nil)
    end
  
    it "should call destroy on the found forum" do
      expect(@mock_forum).to receive(:destroy)
      do_delete
    end
  
    it "should render destroy.rjs" do
      do_delete
      expect(response).to render_template('destroy')
    end
  end
end
