require 'spec_helper'

module InterestsViaUserSpecHelper
  def setup_mocks
    @user = double('User')
    @user_interests = double('user_interests assoc')
    allow(User).to receive(:find_by_login).and_return(@user)
    allow(@user).to receive(:interests).and_return(@user_interests)
    allow(@user).to receive(:to_param).and_return('dave')
  end
end

describe InterestsController do
  describe "Routing shortcuts for Interests via User (users/dave/interests/2) should map" do
    include InterestsViaUserSpecHelper
  
    before(:each) do
      setup_mocks
      @interest = double('Interest')
      allow(@interest).to receive(:to_param).and_return('2')
      allow(@user_interests).to receive(:find).and_return(@interest)
    
      get :show, params: { :user_id => "dave", :id => "2" }
    end
  
    it "resources_path to /users/dave/interests" do
      expect(controller.resources_path).to eq('/users/dave/interests')
    end

    it "resource_path to /users/dave/interests/2" do
      expect(controller.resource_path).to eq('/users/dave/interests/2')
    end
  
    it "resource_path(9) to /users/dave/interests/9" do
      expect(controller.resource_path(9)).to eq('/users/dave/interests/9')
    end

    it "edit_resource_path to /users/dave/interests/2/edit" do
      expect(controller.edit_resource_path).to eq('/users/dave/interests/2/edit')
    end
  
    it "edit_resource_path(9) to /users/dave/interests/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/users/dave/interests/9/edit')
    end
  
    it "new_resource_path to /users/dave/interests/new" do
      expect(controller.new_resource_path).to eq('/users/dave/interests/new')
    end
  end

  describe "resource_service in InterestsController via User" do
  
    before(:each) do
      @user           = User.create :login => 'dave'
      @interest       = Interest.create :interested_in_id => @user.id, :interested_in_type => 'User'
      @other_user     = User.create
      @other_interest = Interest.create :interested_in_id => @other_user.id, :interested_in_type => 'User'
    
      get :index, params: { :user_id => @user.login }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new interest with @user fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Interest)
      expect(resource.interested_in_id).to eq(@user.id)
      expect(resource.interested_in_type).to eq('User')
    end
  
    it "should find @interest with find(@interest.id)" do
      resource = @resource_service.find(@interest.id)
      expect(resource).to eq(@interest)
    end
  
    it "should raise RecordNotFound with find(@other_interest.id)" do
      expect{ @resource_service.find(@other_interest.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only interests belonging to @user with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Interest.where(interested_in_id: @user.id, interested_in_type: 'User').all)
    end
  end

  describe "Requesting /users/dave/interests using GET" do
    include InterestsViaUserSpecHelper

    before(:each) do
      setup_mocks
      @interests = double('Interests')
      allow(@user_interests).to receive(:all).and_return(@interests)
    end
  
    def do_get
      get :index, params: { :user_id => "dave" }
    end

    it "should find the user" do
      expect(User).to receive(:find_by_login).with('dave').and_return(@user)
      do_get
    end

    it "should assign the found user as :interested_in for the view" do
      do_get
      expect(assigns[:interested_in]).to eq(@user)
    end

    it "should assign the user_interests association as the interests resource_service" do
      expect(@user).to receive(:interests).and_return(@user_interests)
      do_get
      expect(@controller.resource_service).to eq(@user_interests)
    end
  end
end
