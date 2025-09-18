require 'spec_helper'

module OwnersControllerSpecHelper
  def setup_mocks
    @forum = double('forum')
    allow(@forum).to receive(:id).and_return(2)
    allow(@forum).to receive(:to_param).and_return('2')
    allow(Forum).to receive(:find).and_return(@forum)
    @owner = mock_model(User)
    allow(@forum).to receive(:owner).and_return(@owner)    
  end
end

describe OwnersController do
  describe "Routing shortcuts for ForumOwner should map" do
    include OwnersControllerSpecHelper
  
    before(:each) do
      setup_mocks
      get :show, params: { :forum_id => "2" }
    end

    it "resource_path to /forums/2/owner" do
      expect(controller.resource_path).to eq('/forums/2/owner')
    end
  
    it "resource_path(:foo => 'bar') to /forums/2/owner?foo=bar" do
      expect(controller.resource_path(:foo => 'bar')).to eq('/forums/2/owner?foo=bar')
    end
  
    it "edit_resource_path to /forums/2/owner/edit" do
      expect(controller.edit_resource_path).to eq('/forums/2/owner/edit')
    end
    
    it "new_resource_path to /forums/2/owner/new" do
      expect(controller.new_resource_path).to eq('/forums/2/owner/new')
    end
   
    it "resource_posts_path to /forums/2/owner/posts" do
      expect(controller.resource_posts_path).to eq("/forums/2/owner/posts")
    end
  
    it "resource_posts_path(:foo => 'bar') to /forums/2/owner/posts?foo=bar" do
      expect(controller.resource_posts_path(:foo => 'bar')).to eq('/forums/2/owner/posts?foo=bar')
    end
  
    it "resource_post_path(5) to /forums/2/owner/posts/5" do
      expect(controller.resource_post_path(5)).to eq("/forums/2/owner/posts/5")
    end
  
    it "enclosing_resource_path to /forums/2" do
      expect(controller.enclosing_resource_path).to eq("/forums/2")
    end
  end

  describe OwnersController, "#resource_service" do
    include OwnersControllerSpecHelper
  
    before(:each) do
      setup_mocks 
      get :show, params: { :forum_id => "2" }
      @resource_service = controller.send :resource_service
    end
  
    it ".new should call :build_owner on @forum" do
      expect(@forum).to receive(:build_owner).with(:args => 'args')
      @resource_service.new :args => 'args'
    end
  
    it ".find should call :owner on @forum" do
      expect(@forum).to receive(:owner)
      @resource_service.find
    end
  end

  describe "Requesting /forums/2/owner using GET" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
    end
  
    def do_get
      get :show, params: { :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render show.rhtml" do
      do_get
      expect(response).to render_template(:show)
    end
  
    it "should find the forum requested" do
      expect(Forum).to receive(:find).with("2").and_return(@forum)
      do_get
    end
  
    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
    end
  
    it "should find the owner from forum.owner" do
      expect(@forum).to receive(:owner).and_return(@owner)
      do_get
    end
  
    it "should assign the found owner for the view" do
      do_get
      expect(assigns[:owner]).to eq(@owner)
    end
  end

  describe "Requesting /forums/2/owner/new using GET" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
      allow(@forum).to receive(:build_owner).and_return(@owner)
    end
  
    def do_get
      get :new, params: { :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render new.rhtml" do
      do_get
      expect(response).to render_template(:new)
    end
  
    it "should build a new owner" do
      expect(@forum).to receive(:build_owner).and_return(@owner)
      do_get
    end
  end

  describe "Requesting /forums/2/owner/edit using GET" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
    end
  
    def do_get
      get :edit, params: { :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render edit.rhtml" do
      do_get
      expect(response).to render_template(:edit)
    end
  
    it "should find the owner from forum.owner" do
      expect(@forum).to receive(:owner).and_return(@owner)
      do_get
    end
  end

  describe "Requesting /forums/2/owner using POST" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
      allow(@owner).to receive(:save).and_return(true)
      allow(@owner).to receive(:to_param).and_return("1")
      allow(@forum).to receive(:build_owner).and_return(@owner)
    end
  
    def do_post
      post :create, params: { :forum_id => 2, :owner => {:name => 'Fred'} }
    end
  
    it "should build a new owner" do
      expect(@forum).to receive(:build_owner) do |params|
        expect(params).to be_a(ActionController::Parameters)
        expect(params.permitted?).to be true
        expect(params.to_h).to eq('name' => 'Fred')
        @owner
      end
      do_post
    end

    it "should set the flash notice" do
      do_post
      expect(flash[:notice]).to eq("Owner was successfully created.")
    end

    it "should redirect to the new owner" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/2/owner")
    end
  
    it "should render new when post unsuccessful" do
      allow(@owner).to receive(:save).and_return(false)
      do_post
      expect(response).to render_template('new')
    end
  end


  describe "Requesting /forums/2/owner using PUT" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
      allow(@owner).to receive(:update).and_return(true)
    end
  
    def do_update
      put :update, params: { :forum_id => "2", :owner => {:name => 'Fred'} }
    end
  
    it "should find the owner from forum.owner" do
      expect(@forum).to receive(:owner).and_return(@owner)
      do_update
    end

    it "should set the flash notice" do
      do_update
      expect(flash[:notice]).to eq("Owner was successfully updated.")
    end

    it "should update the owner" do
      expect(@owner).to receive(:update) do |params|
        expect(params).to be_a(ActionController::Parameters)
        expect(params.permitted?).to be true
        expect(params.to_h).to eq('name' => 'Fred')
      end
      do_update
    end

    it "should redirect to the owner" do
      do_update
      expect(response).to redirect_to("http://test.host/forums/2/owner")
    end
  end


  describe "Requesting /forums/2/owner using DELETE" do
    include OwnersControllerSpecHelper

    before(:each) do
      setup_mocks
      allow(@owner).to receive(:destroy).and_return(@owner)
    end
  
    def do_delete
      delete :destroy, params: { :forum_id => "2" }
    end

    it "should find the owner from forum.owner" do
      expect(@forum).to receive(:owner).and_return(@owner)
      do_delete
    end
  
    it "should call destroy on the owner" do
      expect(@owner).to receive(:destroy).and_return(@owner)
      do_delete
    end
  
    it "should set the flash notice" do
      do_delete
      expect(flash[:notice]).to eq('Owner was successfully destroyed.')
    end
  
    it "should redirect to forums/2" do
      do_delete
      expect(response).to redirect_to("http://test.host/forums/2")
    end
  end
end
