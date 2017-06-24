require 'spec_helper'

module TagsViaUserAddressSpecHelper
  def setup_mocks
    @user = mock_model(User)
    allow(User).to receive(:find_by_login).and_return(@user)
    allow(@user).to receive(:to_param).and_return('dave')
    @user_addresses = double('user_addresses assoc')
    allow(@user).to receive(:addresses).and_return(@user_addresses)
    
    @address = mock_model(Address)
    allow(@user_addresses).to receive(:find).and_return(@address)
    allow(@address).to receive(:to_param).and_return('2')
    @address_tags = double('address_tags assoc')
    allow(@address).to receive(:tags).and_return(@address_tags)
  end
end

describe TagsController do
  describe "Routing shortcuts for Tags via User and Address (users/dave/addresses/2/tags/3) should map" do
    include TagsViaUserAddressSpecHelper
  
    before(:each) do
      setup_mocks
      @tag = mock_model(Tag)
      allow(@tag).to receive(:to_param).and_return('3')
      allow(@address_tags).to receive(:find).and_return(@tag)
    
      get :show, params: { :user_id => "dave", :address_id => "2", :id => "3" }
    end
  
    it "resources_path to /users/dave/addresses/2/tags" do
      expect(controller.resources_path).to eq('/users/dave/addresses/2/tags')
    end

    it "resource_path to /users/dave/addresses/2/tags/3" do
      expect(controller.resource_path).to eq('/users/dave/addresses/2/tags/3')
    end
  
    it "resource_path(9) to /users/dave/addresses/2/tags/9" do
      expect(controller.resource_path(9)).to eq('/users/dave/addresses/2/tags/9')
    end

    it "edit_resource_path to /users/dave/addresses/2/tags/3/edit" do
      expect(controller.edit_resource_path).to eq('/users/dave/addresses/2/tags/3/edit')
    end
  
    it "edit_resource_path(9) to /users/dave/addresses/2/tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/users/dave/addresses/2/tags/9/edit')
    end
  
    it "new_resource_path to /users/dave/addresses/2/tags/new" do
      expect(controller.new_resource_path).to eq('/users/dave/addresses/2/tags/new')
    end
  
    it "enclosing_resource_path to /users/dave/addresses/2" do
      expect(controller.enclosing_resource_path).to eq("/users/dave/addresses/2")
    end
  end

  describe "resource_service in TagsController via User and Address" do
  
    before(:each) do
      @user       = User.create
      @address        = Address.create :user_id => @user.id
      @tag         = Tag.create :taggable_id => @address.id, :taggable_type => 'Address'
      @other_address  = Address.create :user_id => @user.id
      @other_tag   = Tag.create :taggable_id => @other_address.id, :taggable_type => 'Address'
    
      get :index, params: { :user_id => @user.id, :address_id => @address.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new tag with @address fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Tag)
      expect(resource.taggable_id).to eq(@address.id)
      expect(resource.taggable_type).to eq('Address')
    end
  
    it "should find @tag with find(@tag.id)" do
      resource = @resource_service.find(@tag.id)
      expect(resource).to eq(@tag)
    end
  
    it "should raise RecordNotFound with find(@other_tag.id)" do
      expect{ @resource_service.find(@other_tag.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only tags belonging to @address with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Tag.where(taggable_id: @address.id, taggable_type: 'Address').all)
    end
  end

  describe "Requesting /users/dave/addresses/2/tags using GET" do
    include TagsViaUserAddressSpecHelper

    before(:each) do
      setup_mocks
      @tags = double('Tags')
      allow(@address_tags).to receive(:all).and_return(@tags)
    end
  
    def do_get
      get :index, params: { :user_id => "dave", :address_id => '2' }
    end

    it "should find the user" do
      expect(User).to receive(:find_by_login).with('dave').and_return(@user)
      do_get
    end
  
    it "should find the address" do
      expect(@user_addresses).to receive(:find).with('2').and_return(@address)
      do_get
    end

    it "should assign the found address for the view" do
      do_get
      expect(assigns[:address]).to eq(@address)
    end

    it "should assign the address_tags association as the tags resource_service" do
      expect(@address).to receive(:tags).and_return(@address_tags)
      do_get
      expect(@controller.resource_service).to eq(@address_tags)
    end 
  end
end
