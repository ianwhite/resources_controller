require 'spec_helper'

module InterestsViaForumSpecHelper
  def setup_mocks
    @forum = double('Forum')
    @forum_interests = double('forum_interests assoc')
    allow(Forum).to receive(:find).and_return(@forum)
    allow(@forum).to receive(:interests).and_return(@forum_interests)
    allow(@forum).to receive(:to_param).and_return('1')
  end
end

describe InterestsController do
  describe "Routing shortcuts for Interests via Forum (forums/1/interests/2) should map" do
    include InterestsViaForumSpecHelper
  
    before(:each) do
      setup_mocks
      @interest = double('Interest')
      allow(@interest).to receive(:to_param).and_return('2')
      allow(@forum_interests).to receive(:find).and_return(@interest)
    
      get :show, params: { :forum_id => "1", :id => "2" }
    end
  
    it "resources_path to /forums/1/interests" do
      expect(controller.resources_path).to eq('/forums/1/interests')
    end

    it "resource_path to /forums/1/interests/2" do
      expect(controller.resource_path).to eq('/forums/1/interests/2')
    end
  
    it "resource_path(9) to /forums/1/interests/9" do
      expect(controller.resource_path(9)).to eq('/forums/1/interests/9')
    end

    it "edit_resource_path to /forums/1/interests/2/edit" do
      expect(controller.edit_resource_path).to eq('/forums/1/interests/2/edit')
    end
  
    it "edit_resource_path(9) to /forums/1/interests/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/1/interests/9/edit')
    end
  
    it "new_resource_path to /forums/1/interests/new" do
      expect(controller.new_resource_path).to eq('/forums/1/interests/new')
    end
  end

  describe "Requesting /forums/1/interests using GET" do
    include InterestsViaForumSpecHelper

    before(:each) do
      setup_mocks
      @interests = double('Interests')
      allow(@forum_interests).to receive(:all).and_return(@interests)
    end
  
    def do_get
      get :index, params: { :forum_id => '1' }
    end

    it "should find the forum" do
      expect(Forum).to receive(:find).with('1').and_return(@forum)
      do_get
    end

    it "should assign the found forum as :interested_in for the view" do
      do_get
      expect(assigns[:interested_in]).to eq(@forum)
    end

    it "should assign the forum_interests association as the interests resource_service" do
      expect(@forum).to receive(:interests).and_return(@forum_interests)
      do_get
      expect(@controller.resource_service.service).to be(@forum_interests)
    end 
  end
end
