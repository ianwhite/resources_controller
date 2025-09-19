require 'spec_helper'

module TagsViaForumPostSpecHelper
  def setup_mocks
    @forum = double('Forum')
    allow(Forum).to receive(:find).and_return(@forum)
    allow(@forum).to receive(:to_param).and_return('1')
    @forum_posts = double('forum_posts assoc')
    allow(@forum).to receive(:posts).and_return(@forum_posts)
    
    @post = double('Post')
    allow(@forum_posts).to receive(:find).and_return(@post)
    allow(@post).to receive(:to_param).and_return('2')
    @post_tags = double('post_tags assoc')
    allow(@post).to receive(:tags).and_return(@post_tags)
  end
end

describe TagsController do
  describe "Routing shortcuts for Tags via Forum and Post (forums/1/posts/2/tags/3) should map" do
    include TagsViaForumPostSpecHelper
  
    before(:each) do
      setup_mocks
      @tag = double('Tag')
      allow(@tag).to receive(:to_param).and_return('3')
      allow(@post_tags).to receive(:find).and_return(@tag)
    
      allow(@controller).to receive(:request_path).and_return('/forums/1/posts/1/tags/3')
      get :show, params: { :forum_id => "1", :post_id => "2", :id => "3" }
    end
  
    it "resources_path to /forums/1/posts/2/tags" do
      expect(controller.resources_path).to eq('/forums/1/posts/2/tags')
    end

    it "resource_path to /forums/1/posts/2/tags/3" do
      expect(controller.resource_path).to eq('/forums/1/posts/2/tags/3')
    end
  
    it "resource_path(9) to /forums/1/posts/2/tags/9" do
      expect(controller.resource_path(9)).to eq('/forums/1/posts/2/tags/9')
    end

    it "edit_resource_path to /forums/1/posts/2/tags/3/edit" do
      expect(controller.edit_resource_path).to eq('/forums/1/posts/2/tags/3/edit')
    end
  
    it "edit_resource_path(9) to /forums/1/posts/2/tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/1/posts/2/tags/9/edit')
    end
  
    it "new_resource_path to /forums/1/posts/2/tags/new" do
      expect(controller.new_resource_path).to eq('/forums/1/posts/2/tags/new')
    end
  
    it "enclosing_resource_path to /forums/1/posts/2" do
      expect(controller.enclosing_resource_path).to eq("/forums/1/posts/2")
    end
  end

  describe "resource_service in TagsController via Forum and Post" do
  
    before(:each) do
      @forum       = Forum.create
      @post        = Post.create :forum_id => @forum.id
      @tag         = Tag.create :taggable_id => @post.id, :taggable_type => 'Post'
      @other_post  = Post.create :forum_id => @forum.id
      @other_tag   = Tag.create :taggable_id => @other_post.id, :taggable_type => 'Post'
    
      allow(@controller).to receive(:request_path).and_return("/forums/:id/posts/:id/tags")
      get :index, params: { :forum_id => @forum.id, :post_id => @post.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new tag with @post fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Tag)
      expect(resource.taggable_id).to eq(@post.id)
      expect(resource.taggable_type).to eq('Post')
    end
  
    it "should find @tag with find(@tag.id)" do
      resource = @resource_service.find(@tag.id)
      expect(resource).to eq(@tag)
    end
  
    it "should raise RecordNotFound with find(@other_tag.id)" do
      expect{ @resource_service.find(@other_tag.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only tags belonging to @post with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Tag.where(taggable_id: @post.id, taggable_type: 'Post').all)
    end
  end

  describe "Requesting /forums/1/posts/2/tags using GET" do
    include TagsViaForumPostSpecHelper

    before(:each) do
      setup_mocks
      @tags = double('Tags')
      allow(@post_tags).to receive(:all).and_return(@tags)
    end
  
    def do_get
      allow(@controller).to receive(:request_path).and_return("/forums/1/posts/2/tags")
      get :index, params: { :forum_id => '1', :post_id => '2' }
    end

    it "should find the forum" do
      expect(Forum).to receive(:find).with('1').and_return(@forum)
      do_get
    end
  
    it "should find the post" do
      expect(@forum_posts).to receive(:find).with('2').and_return(@post)
      do_get
    end

    it "should assign the found post for the view" do
      do_get
      expect(assigns[:post]).to eq(@post)
    end

    it "should assign the post_tags association as the tags resource_service" do
      expect(@post).to receive(:tags).and_return(@post_tags)
      do_get
      expect(@controller.resource_service.service).to be(@post_tags)
    end 
  end
end
