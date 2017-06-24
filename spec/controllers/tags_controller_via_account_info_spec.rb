require 'spec_helper'

module TagsViaAccountInfoHelper
  def setup_mocks
    @current_user = double('user')
    allow(@current_user).to receive(:id).and_return('1')
    allow(User).to receive(:find).and_return(@current_user)
    @info = double('info')
    allow(@info).to receive(:id).and_return('3')
    allow(@current_user).to receive(:info).and_return(@info)
    @info_tags = double('info_tags')
    allow(@info).to receive(:tags).and_return(@info_tags)
    @controller.instance_variable_set('@current_user', @current_user)
  end
end

describe TagsController do
  describe "Routing shortcuts for Tags via account info (/account/info/) should map" do
    include TagsViaAccountInfoHelper
  
    before(:each) do
      setup_mocks
      @tag = double('Tag')
      allow(@tag).to receive(:to_param).and_return('2')
      allow(@info_tags).to receive(:find).and_return(@tag)
    
      allow(@controller).to receive(:request_path).and_return('/account/info/tags/2')
      get :show, params: {  :id => 2 }
    end
  
    it "resources_path to /account/info/tags" do
      expect(controller.resources_path).to eq('/account/info/tags')
    end

    it "resource_path to /account/info/tags/2" do
      expect(controller.resource_path).to eq('/account/info/tags/2')
    end
  
    it "resource_path(9) to /account/info/tags/9" do
      expect(controller.resource_path(9)).to eq('/account/info/tags/9')
    end

    it "edit_resource_path to /account/info/tags/2/edit" do
      expect(controller.edit_resource_path).to eq('/account/info/tags/2/edit')
    end
  
    it "edit_resource_path(9) to /account/info/tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/account/info/tags/9/edit')
    end
  
    it "new_resource_path to /account/info/tags/new" do
      expect(controller.new_resource_path).to eq('/account/info/tags/new')
    end
  
    it "enclosing_resource_path to /account/info" do
      expect(controller.enclosing_resource_path).to eq("/account/info")
    end
  end

  describe "resource_service in TagsController via Account Info" do
    include TagsViaAccountInfoHelper
  
    before(:each) do
      @info = Info.create
      @account = User.create :info => @info
      @info.tags << (@tag = Tag.create)
      @other_tag = Tag.create
    
      @controller.instance_variable_set('@current_user', @account)
      allow(@controller).to receive(:request_path).and_return('/account/info/tags')
      get :index
      @resource_service = controller.send :resource_service
    end
  
    it "should build new tag with @info fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Tag)
      expect(resource.taggable_id).to eq(@info.id)
      expect(resource.taggable_type).to eq('Info')
    end
  
    it "should find @tag with find(@tag.id)" do
      resource = @resource_service.find(@tag.id)
      expect(resource).to eq(@tag)
    end
  
    it "should raise RecordNotFound with find(@other_tag.id)" do
      expect{ @resource_service.find(@other_tag.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only tags belonging to @info with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Tag.where(taggable_id: @info.id, taggable_type: 'Info').all)
    end
  end

  describe "Requesting /forums/1/tags using GET" do
    include TagsViaAccountInfoHelper

    before(:each) do
      setup_mocks
      @tags = double('Tags')
      allow(@info_tags).to receive(:all).and_return(@tags)
    end
  
    def do_get
      allow(@controller).to receive(:request_path).and_return('/account/info/tags')
      get :index
    end

    it "should find the account as current_user" do
      do_get
      expect(assigns['account']).to eq(@current_user)
    end

    it "should get info from current_user" do
      expect(@current_user).to receive(:info).and_return(@info)
      do_get
    end

    it "should get tags assoc from info" do
      expect(@info).to receive(:tags).and_return(@info_tags)
      do_get
    end

    it "should get tags from tags assoc" do
      expect(@info_tags).to receive(:all).and_return(@tags)
      do_get
    end
  end
end
