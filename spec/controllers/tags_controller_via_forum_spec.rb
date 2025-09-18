require 'spec_helper'

module TagsViaForumSpecHelper
  def setup_mocks
    @forum = double('Forum')
    @forum_tags = double('forum_tags assoc')
    allow(Forum).to receive(:find).and_return(@forum)
    allow(@forum).to receive(:tags).and_return(@forum_tags)
    allow(@forum).to receive(:to_param).and_return('1')
  end
end

describe TagsController do
  describe "Routing shortcuts for Tags via Forum (forums/1/tags/2) should map" do
    include TagsViaForumSpecHelper
  
    before(:each) do
      setup_mocks
      @tag = double('Tag')
      allow(@tag).to receive(:to_param).and_return('2')
      allow(@forum_tags).to receive(:find).and_return(@tag)
    
      get :show, params: { :forum_id => "1", :id => "2" }
    end
  
    it "resources_path to /forums/1/tags" do
      expect(controller.resources_path).to eq('/forums/1/tags')
    end

    it "resource_path to /forums/1/tags/2" do
      expect(controller.resource_path).to eq('/forums/1/tags/2')
    end
  
    it "resource_path(9) to /forums/1/tags/9" do
      expect(controller.resource_path(9)).to eq('/forums/1/tags/9')
    end

    it "edit_resource_path to /forums/1/tags/2/edit" do
      expect(controller.edit_resource_path).to eq('/forums/1/tags/2/edit')
    end
  
    it "edit_resource_path(9) to /forums/1/tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/1/tags/9/edit')
    end
  
    it "new_resource_path to /forums/1/tags/new" do
      expect(controller.new_resource_path).to eq('/forums/1/tags/new')
    end
  
    it "enclosing_resource_path to /forums/1" do
      expect(controller.enclosing_resource_path).to eq("/forums/1")
    end
  end

  describe "resource_service in TagsController via Forum" do
  
    before(:each) do
      @forum       = Forum.create
      @tag         = Tag.create :taggable_id => @forum.id, :taggable_type => 'Forum'
      @other_forum = Forum.create
      @other_tag   = Tag.create :taggable_id => @other_forum.id, :taggable_type => 'Forum'
    
      get :new, params: { :forum_id => @forum.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new tag with @forum fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Tag)
      expect(resource.taggable_id).to eq(@forum.id)
      expect(resource.taggable_type).to eq('Forum')
    end
  
    it "should find @tag with find(@tag.id)" do
      resource = @resource_service.find(@tag.id)
      expect(resource).to eq(@tag)
    end
  
    it "should raise RecordNotFound with find(@other_tag.id)" do
      expect{ @resource_service.find(@other_tag.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only tags belonging to @forum with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Tag.where(taggable_id: @forum.id, taggable_type: 'Forum').all)
    end
  end

  describe "Requesting /forums/1/tags using GET" do
    include TagsViaForumSpecHelper

    before(:each) do
      setup_mocks
      @tags = double('Tags')
      allow(@forum_tags).to receive(:all).and_return(@tags)
    end
  
    def do_get
      get :index, params: { :forum_id => '1' }
    end

    it "should find the forum" do
      expect(Forum).to receive(:find).with('1').and_return(@forum)
      do_get
    end

    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
    end

    it "should assign the forum_tags association as the tags resource_service" do
      expect(@forum).to receive(:tags).and_return(@forum_tags)
      do_get
      expect(@controller.resource_service.service).to be(@forum_tags)
    end 
  end

  describe "Requesting /forums/1/tags/new using GET" do
    include TagsViaForumSpecHelper

    before(:each) do
      setup_mocks
      @tag = double('Tag')
      allow(@forum_tags).to receive(:build).and_return(@tag)
    end
  
    def do_get
      get :new, params: { :forum_id => '1', :tag => {"name" => "hello"} }
    end

    it "should find the forum" do
      expect(Forum).to receive(:find).with('1').and_return(@forum)
      do_get
    end

    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
    end

    it "should assign the forum_tags association as the tags resource_service" do
      expect(@forum).to receive(:tags).and_return(@forum_tags)
      do_get
      expect(@controller.resource_service.service).to be(@forum_tags)
    end
  
    it "should render new template" do
      do_get
      expect(response).to render_template('new')
    end
  
    it "should build a new tag with params" do
      expect(@forum_tags).to receive(:build) do |params|
        expect(params).to be_a(ActionController::Parameters)
        expect(params.permitted?).to be true
        expect(params.to_h).to eq('name' => 'hello')
        @tag
      end
      do_get
    end
  
    it "should not save the new category" do
      expect(@tag).not_to receive(:save)
      do_get
    end
  
    it "should assign the new tag for the view" do
      do_get
      expect(assigns[:tag]).to equal(@tag)
    end
  
    it "should send :resource= to controller with @tag" do
      expect(controller).to receive(:resource=).with(@tag)
      do_get
    end
  end
end
