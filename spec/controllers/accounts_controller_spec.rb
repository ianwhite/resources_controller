require 'spec_helper'

module AccountsControllerSpecHelper
  def setup_mocks
    @current_user = double('user')
    allow(@current_user).to receive(:id).and_return('1')
    allow(User).to receive(:find).and_return(@current_user)
    @controller.instance_variable_set('@current_user', @current_user)
  end
end

describe AccountsController do
  describe "Routing shortcuts for Account should map" do
    include AccountsControllerSpecHelper
  
    before(:each) do
      setup_mocks
      get :show
    end

    it "resource_path to /account" do
      expect(controller.resource_path).to eq('/account')
    end
   
    it "resource_info_tags_path to /account/info/tags" do
      expect(controller.resource_info_tags_path).to eq("/account/info/tags")
    end    
  end

  describe AccountsController, " requesting garbage url" do
    it "should raise ResourcesController::Specification::NoClassFoundError" do
      expect { get :show, params: { :resource_path => "/crayzeee" }}.to raise_error(ResourcesController::Specification::NoClassFoundError)
    end
  end
  
  describe AccountsController, "#resource_service" do
    include AccountsControllerSpecHelper
  
    before(:each) do
      setup_mocks 
      get :show
      @resource_service = controller.send :resource_service
    end
  
    it ".new should call :new on User" do
      expect(User).to receive(:new).with(:args => 'args')
      @resource_service.new :args => 'args'
    end
  
    it ".find should call :current_user" do
      expect(@controller).to receive(:current_user).once.and_return(@current_user)
      @resource_service.find
    end
  
    it ".find should call whatever is in resource_specification @find" do
      expect(@controller).to receive(:lambda_called).once.and_return(@current_user)
      resource_specification = @controller.send(:resource_specification)
      allow(resource_specification).to receive(:find).and_return(lambda { lambda_called })
      @resource_service.find
    end
  
    it ".find should raise CantFindSingleton when no custom finder (and no enclosing resource)" do
      allow(@controller.send(:resource_specification)).to receive(:find).and_return nil
      expect{ @resource_service.find }.to raise_error(ResourcesController::CantFindSingleton)
    end
  
    it ".foo should call foo on User" do
      expect(User).to receive(:foo).once
      @resource_service.foo
    end
  
    it ".respond_to?(:foo) should call respond_to?(:foo) on User" do
      allow(User).to receive(:foo)
      expect(@resource_service.respond_to?(:foo)).to be true
    end
  end
end
