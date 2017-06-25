require 'spec_helper'

describe TagsController do
  describe "Routing shortcuts for Tags should map" do
  
    before(:each) do
      @tag = double('Tag')
      allow(@tag).to receive(:to_param).and_return('2')
      allow(Tag).to receive(:find).and_return(@tag)
    
      allow(@controller).to receive(:request_path).and_return('/tags/2')
      get :show, params: { :id => "2" }
    end
  
    it "resources_path to /tags" do
      expect(controller.resources_path).to eq('/tags')
    end

    it "resource_path to /tags/2" do
      expect(controller.resource_path).to eq('/tags/2')
    end
  
    it "resource_path(9) to /tags/9" do
      expect(controller.resource_path(9)).to eq('/tags/9')
    end

    it "edit_resource_path to /tags/2/edit" do
      expect(controller.edit_resource_path).to eq('/tags/2/edit')
    end
  
    it "edit_resource_path(9) to /tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/tags/9/edit')
    end
  
    it "new_resource_path to /forums/1/tags/new" do
      expect(controller.new_resource_path).to eq('/tags/new')
    end
  
    it "enclosing_resource_path should raise error" do
      expect{ controller.enclosing_resource_path }.to raise_error(NoMethodError)
    end
  end

  describe "resource_service in TagsController" do
  
    before(:each) do
      @resource_service = controller.send :resource_service
    end
  
    it ".new should call new on Tag" do
      expect(Tag).to receive(:new).with(:args => "args")
      resource = @resource_service.new(:args => "args")
    end
  
    it ".find should call find on Tag" do
      expect(Tag).to receive(:find).with(:id)
      resource = @resource_service.find(:id)
    end
  end

  describe "Requesting /tags/index" do

    before(:each) do
      @tags = double('Tags')
      allow(Tag).to receive(:all).and_return(@tags)
    end
  
    def do_get
      allow(@controller).to receive(:request_path).and_return('/tags/index')
      get :index
    end

    it "should find the tags" do
      expect(Tag).to receive(:all).and_return(@tags)
      do_get
    end

    it "should assign the tags for the view" do
      do_get
      expect(assigns[:tags]).to eq(@tags)
    end
  end
end
