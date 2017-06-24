require 'spec_helper'

module AddressesSpecHelper
  def setup_mocks
    @user = double('User')
    @user_addresses = double('Assoc: user_addresses')
    allow(@user).to receive(:addresses).and_return(@user_addresses)
    allow(@user).to receive(:to_param).and_return("dave")
    
    allow(User).to receive(:find_by_login).and_return(@user)
  end
end

describe AddressesController do
  describe "Routing shortcuts for Addresses (users/dave/addresses/1) should map" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('Address')
      allow(@address).to receive(:to_param).and_return('1')
      allow(@user_addresses).to receive(:find).and_return(@address)
  
      get :show, params: { :user_id => "dave", :id => "1" }
    end
  
    it "resources_path to /users/dave/addresses" do
      expect(controller.resources_path).to eq('/users/dave/addresses')
    end

    it "resource_path to /users/dave/addresses/1" do
      expect(controller.resource_path).to eq('/users/dave/addresses/1')
    end
  
    it "resource_path(9) to /users/dave/addresses/9" do
      expect(controller.resource_path(9)).to eq('/users/dave/addresses/9')
    end

    it "edit_resource_path to /users/dave/addresses/1/edit" do
      expect(controller.edit_resource_path).to eq('/users/dave/addresses/1/edit')
    end
  
    it "edit_resource_path(9) to /users/dave/addresses/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/users/dave/addresses/9/edit')
    end
  
    it "new_resource_path to /users/dave/addresses/new" do
      expect(controller.new_resource_path).to eq('/users/dave/addresses/new')
    end
  end

  describe "resource_service in AddressesController" do
  
    before(:each) do
      @user          = User.create :login => 'dave'
      @address       = Address.create :user_id => @user.id
      @other_user    = User.create
      @other_address = Address.create :user_id => @other_user.id
    
      get :index, params: { :user_id => 'dave' }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new address with @user foreign key with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Address)
      expect(resource.user_id).to eq(@user.id)
    end
  
    it "should find @address with find(@address.id)" do
      resource = @resource_service.find(@address.id)
      expect(resource).to eq(@address)
    end
  
    it "should raise RecordNotFound with find(@other_address.id)" do
      expect{ @resource_service.find(@other_address.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only addresses belonging to @user with find(:all)" do
      resources = @resource_service.all
      expect(resources).to eq(Address.where(user_id: @user.id).all)
    end
  end

  describe "Requesting /users/dave/addresses" do
    include AddressesSpecHelper
  
    before(:each) do
      setup_mocks
      @addresses = double('Addresses')
      allow(@user_addresses).to receive(:all).and_return(@addresses)
    end
  
    def do_get
      get :index, params: { :user_id => 'dave' }
    end
    
    it "should find the user" do
      expect(User).to receive(:find_by_login).with('dave').and_return(@user)
      do_get
    end
  
    it "should assign the found user for the view" do
      do_get
      expect(assigns[:user]).to eq(@user)
    end
  
    it "should assign the user_addresses association as the addresses resource_service" do
      expect(@user).to receive(:addresses).and_return(@user_addresses)
      do_get
      expect(@controller.resource_service).to eq(@user_addresses)
    end 
  end

  describe "Requesting /users/dave/addresses using GET" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @addresses = double('Addresses')
      allow(@user_addresses).to receive(:all).and_return(@addresses)
    end
  
    def do_get
      get :index, params: { :user_id => '2' }
    end
  
    it "should be successful" do
      do_get
      expect(response).to be_success
    end

    it "should render index.rhtml" do
      do_get
      expect(response).to render_template(:index)
    end
  
    it "should find all addresses" do
      expect(@user_addresses).to receive(:all).and_return(@addresses)
      do_get
    end
  
    it "should assign the found addresses for the view" do
      do_get
      expect(assigns[:addresses]).to eq(@addresses)
    end
  end

  describe "Requesting /users/dave/addresses/1 using GET" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('a address')
      allow(@user_addresses).to receive(:find).and_return(@address)
    end
  
    def do_get
      get :show, params: { :id => "1", :user_id => "dave" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render show.rhtml" do
      do_get
      expect(response).to render_template(:show)
    end
  
    it "should find the thing requested" do
      expect(@user_addresses).to receive(:find).with("1").and_return(@address)
      do_get
    end
  
    it "should assign the found thing for the view" do
      do_get
      expect(assigns[:address]).to eq(@address)
    end
  end

  describe "Requesting /users/dave/addresses/new using GET" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('new Address')
      allow(@user_addresses).to receive(:build).and_return(@address)
    end
  
    def do_get
      get :new, params: { :user_id => "dave" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render new.rhtml" do
      do_get
      expect(response).to render_template(:new)
    end
  
    it "should create an new thing" do
      expect(@user_addresses).to receive(:build).and_return(@address)
      do_get
    end
  
    it "should not save the new thing" do
      expect(@address).not_to receive(:save)
      do_get
    end
  
    it "should assign the new thing for the view" do
      do_get
      expect(assigns[:address]).to eq(@address)
    end
  end

  describe "Requesting /users/dave/addresses/1/edit using GET" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('Address')
      allow(@user_addresses).to receive(:find).and_return(@address)
    end
 
    def do_get
      get :edit, params: { :id => "1", :user_id => "dave" }
    end

    it "should be successful" do
      do_get
      expect(response).to be_success
    end
  
    it "should render edit.rhtml" do
      do_get
      expect(response).to render_template(:edit)
    end
  
    it "should find the thing requested" do
      expect(@user_addresses).to receive(:find).with("1").and_return(@address)
      do_get
    end
  
    it "should assign the found Thing for the view" do
      do_get
      expect(assigns(:address)).to equal(@address)
    end
  end

  describe "Requesting /users/dave/addresses using POST" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('Address')
      allow(@address).to receive(:save).and_return(true)
      allow(@address).to receive(:to_param).and_return("1")
      allow(@user_addresses).to receive(:build).and_return(@address)
    end
  
    def do_post
      post :create, params: { :address => {:name => 'Address'}, :user_id => "dave" }
    end
  
    it "should create a new address" do
      expect(@user_addresses).to receive(:build).with({'name' => 'Address'}).and_return(@address)
      do_post
    end

    it "should redirect to the new address" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/users/dave/addresses/1")
    end
  end

  describe "Requesting /users/dave/addresses/1 using PUT" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('Address').as_null_object
      allow(@address).to receive(:to_param).and_return("1")
      allow(@user_addresses).to receive(:find).and_return(@address)
    end
  
    def do_update
      put :update, params: { :id => "1", :user_id => "dave" }
    end
  
    it "should find the address requested" do
      expect(@user_addresses).to receive(:find).with("1").and_return(@address)
      do_update
    end

    it "should update the found address" do
      expect(@address).to receive(:update_attributes).and_return(true)
      do_update
    end

    it "should assign the found address for the view" do
      do_update
      expect(assigns(:address)).to eq(@address)
    end

    it "should redirect to the address" do
      do_update
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/users/dave/addresses/1")
    end
  end

  describe "Requesting /users/dave/addresses/1 using DELETE" do
    include AddressesSpecHelper

    before(:each) do
      setup_mocks
      @address = double('Address', :id => "1").as_null_object
      allow(@user_addresses).to receive(:find).and_return(@address)
      allow(@user_addresses).to receive(:destroy)
    end
  
    def do_delete
      delete :destroy, params: { :id => "1", :user_id => "dave" }
    end

    it "should find and destroy the address requested" do
      expect(@user_addresses).to receive(:find).with("1").and_return(@address)
      expect(@user_addresses).to receive(:destroy).with("1")
      do_delete
      expect(assigns(:address)).to eq(@address)
    end
  
    it "should redirect to the things list" do
      do_delete
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/users/dave/addresses")
    end
  end
end
