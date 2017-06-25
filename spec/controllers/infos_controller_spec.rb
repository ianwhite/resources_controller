require 'spec_helper'

module InfosControllerSpecHelper
  def setup_mocks
    @current_user = double('user')
    allow(@current_user).to receive(:id).and_return('1')
    allow(@controller).to receive(:current_user).and_return(@current_user)
    @info = double('info')
    allow(@info).to receive(:id).and_return('3')
    allow(@current_user).to receive(:info).and_return(@info)
  end
end

describe InfosController do
  describe "Routing shortcuts for Infos should map" do
    include InfosControllerSpecHelper
  
    before(:each) do
      setup_mocks
      get :show
    end

    it "resource_path to /account/info" do
      expect(controller.resource_path).to eq('/account/info')
    end
  
    it "resource_tags_path to /account/info/tags" do
      expect(controller.resource_tags_path).to eq("/account/info/tags")
    end    
  end

  describe InfosController, " (its actions)" do
    include InfosControllerSpecHelper
  
    before do
      setup_mocks
    end
  
    it "should not have ['new', 'index', 'destroy', 'create'] in action_methods" do
      expect(@controller.class.send(:action_methods) & Set.new(['new', 'index', 'destroy', 'create'])).to be_empty
    end
  
    it "GET /account/info should be successful" do
      get :show
      expect(response).to be_success
    end

    it "GET /account/info/edit should be successful" do
      get :edit
      expect(response).to be_success
    end
  
    it "PUT /account/info should be successful" do
      allow(@info).to receive(:update).and_return(true)
      put :update
      expect(response).to be_redirect
    end
  
    it "GET /account/info/new should raise ActionNotFound" do
      expect { get :new }.to raise_error(::AbstractController::ActionNotFound)
    end
  
    it "POST /account/info should raise ActionNotFound" do
      expect { post :create }.to raise_error(::AbstractController::ActionNotFound)
    end

    it "DELETE /account/info/new should raise ActionNotFound" do
      expect { delete :destroy }.to raise_error(::AbstractController::ActionNotFound)
    end
  end
end
