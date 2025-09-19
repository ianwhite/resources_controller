require 'spec_helper'

module TagsViaForumPostCommentSpecHelper
  def setup_mocks
    @forum = double('Forum')
    allow(Forum).to receive(:find).and_return(@forum)
    allow(@forum).to receive(:to_param).and_return('1')
    @forum_posts = double('forum_posts assoc')
    allow(@forum).to receive(:posts).and_return(@forum_posts)
    
    @post = double('Post')
    allow(@forum_posts).to receive(:find).and_return(@post)
    allow(@post).to receive(:to_param).and_return('2')
    @post_comments = double('post_comments assoc')
    allow(@post).to receive(:comments).and_return(@post_comments)
    
    @comment = double('Comment')
    allow(@post_comments).to receive(:find).and_return(@comment)
    allow(@comment).to receive(:to_param).and_return('3')
    @comment_tags = double('comment_tags assoc')
    allow(@comment).to receive(:tags).and_return(@comment_tags)
  end
end

describe TagsController do
  describe "Routing shortcuts for Tags via Forum, Post and Comment (forums/1/posts/2/comments/3tags/4) should map" do
    include TagsViaForumPostCommentSpecHelper
  
    before(:each) do
      setup_mocks
      @tag = double('Tag')
      allow(@tag).to receive(:to_param).and_return('4')
      allow(@comment_tags).to receive(:find).and_return(@tag)
    
      get :show, params: { :forum_id => "1", :post_id => "2", :comment_id => '3', :id => "4" }
    end
  
    it "resources_path to /forums/1/posts/2/comments/3/tags" do
      expect(controller.resources_path).to eq('/forums/1/posts/2/comments/3/tags')
    end

    it "resource_path to /forums/1/posts/2/comments/3/tags/4" do
      expect(controller.resource_path).to eq('/forums/1/posts/2/comments/3/tags/4')
    end
  
    it "resource_path(9) to /forums/1/posts/2/comments/3/tags/9" do
      expect(controller.resource_path(9)).to eq('/forums/1/posts/2/comments/3/tags/9')
    end

    it "edit_resource_path to /forums/1/posts/2/comments/3/tags/4/edit" do
      expect(controller.edit_resource_path).to eq('/forums/1/posts/2/comments/3/tags/4/edit')
    end
  
    it "edit_resource_path(9) to /forums/1/posts/2/comments/3/tags/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/1/posts/2/comments/3/tags/9/edit')
    end
  
    it "new_resource_path to /forums/1/posts/2/comments/3/tags/new" do
      expect(controller.new_resource_path).to eq('/forums/1/posts/2/comments/3/tags/new')
    end
  
    it "enclosing_resource_path to /forums/1/posts/2/comments/3" do
      expect(controller.enclosing_resource_path).to eq("/forums/1/posts/2/comments/3")
    end
  end

  describe "resource_service in TagsController via Forum, Post and Comment" do
  
    before(:each) do
      @forum         = Forum.create
      @post          = Post.create :forum_id => @forum.id
      @comment       = Comment.create :post_id => @post.id, :user => User.create!
      @tag           = Tag.create :taggable_id => @comment.id, :taggable_type => 'Comment'
      @other_comment = Comment.create :post_id => @forum.id
      @other_tag     = Tag.create :taggable_id => @other_comment.id, :taggable_type => 'Comment'
    
      get :index, params: { :forum_id => @forum.id, :post_id => @post.id, :comment_id => @comment.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new tag with @comment fk and type with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Tag)
      expect(resource.taggable_id).to eq(@comment.id)
      expect(resource.taggable_type).to eq('Comment')
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
      expect(resources).to eq(Tag.where(taggable_id: @comment.id, taggable_type: 'Comment').all)
    end
  end

  describe "Requesting /forums/1/posts/2/comment/3/tags using GET" do
    include TagsViaForumPostCommentSpecHelper

    before(:each) do
      setup_mocks
      @tags = double('Tags')
      allow(@comment_tags).to receive(:all).and_return(@tags)
    end
  
    def do_get
      get :index, params: { :forum_id => '1', :post_id => '2', :comment_id => '3' }
    end

    it "should find the forum" do
      expect(Forum).to receive(:find).with('1').and_return(@forum)
      do_get
    end
  
    it "should find the post" do
      expect(@forum_posts).to receive(:find).with('2').and_return(@post)
      do_get
    end

    it "should find the comment" do
      expect(@post_comments).to receive(:find).with('3').and_return(@comment)
      do_get
    end

    it "should assign the found forum, post, and comment for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
      expect(assigns[:post]).to eq(@post)
      expect(assigns[:comment]).to eq(@comment)
    end

    it "should assign the comment_tags association as the tags resource_service" do
      expect(@comment).to receive(:tags).and_return(@comment_tags)
      do_get
      expect(@controller.resource_service.service).to be(@comment_tags)
    end 
  end
end
