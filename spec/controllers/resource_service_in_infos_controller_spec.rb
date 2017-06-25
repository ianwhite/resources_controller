require 'spec_helper'

describe InfosController do
  describe "resource_service in InfosController via Account(a user)" do
  
    before(:each) do
      @account    = User.create!
      @info       = Info.create! :user_id => @account.id
    
      allow(@controller).to receive(:current_user).and_return(@account)
    
      get :show, params: { :resource_path => '/account/info' }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new interest on the account" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Info)
      expect(resource.user_id).to eq(@account.id)
    end
  
    it "should find @info with find" do
      resource = @resource_service.find
      expect(resource).to eq(@info)
    end
  
    it "should destroy the info with destroy" do
      expect { @resource_service.destroy }.to change(Info, :count).by(-1)
      expect { Info.find(@info.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  
    it "should return the destroyed info with destroy" do
      expect(@resource_service.destroy).to eq(@info)
    end
  end
end
