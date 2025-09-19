require 'spec_helper'

module CommentsSpecHelper
  def setup_mocks
    @forum = double('Forum')
    @forum_posts = double('Assoc: forum_posts')
    allow(@forum).to receive(:posts).and_return(@forum_posts)
    allow(@forum).to receive(:to_param).and_return("3")
    
    @post = double('Post')
    @post_comments = double('Assoc: post_comments')
    allow(@post).to receive(:comments).and_return(@post_comments)
    allow(@post).to receive(:to_param).and_return("2")
        
    allow(Forum).to receive(:find).and_return(@forum)
    allow(@forum_posts).to receive(:find).and_return(@post)
  end
end

describe CommentsController do
  describe "Routing shortcuts for Comments (forums/3/posts/2/comments/1) should map" do
    include CommentsSpecHelper
  
    before(:each) do
      setup_mocks
      @comment = double('Comment')
      allow(@comment).to receive(:to_param).and_return("1")
      allow(@post_comments).to receive(:find).and_return(@comment)
      get :show, params: { :forum_id => "3", :post_id => "2", :id => "1" }
    end
  
    it "resources_path to /forums/3/posts/2/comments" do
      expect(controller.resources_path).to eq('/forums/3/posts/2/comments')
    end

    it "resource_path to /forums/3/posts/2/comments/1" do
      expect(controller.resource_path).to eq('/forums/3/posts/2/comments/1')
    end
  
    it "resource_path(9) to /forums/3/posts/2/comments/9" do
      expect(controller.resource_path(9)).to eq('/forums/3/posts/2/comments/9')
    end

    it "edit_resource_path to /forums/3/posts/2/comments/1/edit" do
      expect(controller.edit_resource_path).to eq('/forums/3/posts/2/comments/1/edit')
    end
  
    it "edit_resource_path(9) to /forums/3/posts/2/comments/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/3/posts/2/comments/9/edit')
    end
  
    it "new_resource_path to /forums/3/posts/2/comments/new" do
      expect(controller.new_resource_path).to eq('/forums/3/posts/2/comments/new')
    end
  
    it "resource_tags_path to /forums/3/posts/2/comments/1/tags" do
      expect(controller.resource_tags_path).to eq("/forums/3/posts/2/comments/1/tags")
    end

    it "resource_tags_path(9) to /forums/3/posts/2/comments/9/tags" do
      expect(controller.resource_tags_path(9)).to eq("/forums/3/posts/2/comments/9/tags") 
    end
  
    it "resource_tag_path(5) to /forums/3/posts/2/comments/1/tags/5" do
      expect(controller.resource_tag_path(5)).to eq("/forums/3/posts/2/comments/1/tags/5")
    end
  
    it "resource_tag_path(9,5) to /forums/3/posts/2/comments/9/tags/5" do
      expect(controller.resource_tag_path(9,5)).to eq("/forums/3/posts/2/comments/9/tags/5")
    end
  end

  describe "resource_service in CommentsController" do
  
    before(:each) do
      @forum          = Forum.create
      @post           = Post.create :forum_id => @forum.id
      @comment        = Comment.create :post_id => @post.id, :user => User.create
      @other_post     = Post.create :forum_id => @forum.id
      @other_comment  = Comment.create :post_id => @other_post.id
    
      get :index, params: { :forum_id => @forum.id, :post_id => @post.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new comment with @post foreign key with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Comment)
      expect(resource.post_id).to eq(@post.id)
    end
  
    it "should find @comment with find(@comment.id)" do
      resource = @resource_service.find(@comment.id)
      expect(resource).to eq(@comment)
    end
  
    it "should raise RecordNotFound with find(@other_post.id)" do
      expect{ @resource_service.find(@other_comment.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only comments belonging to @post with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Comment.where(post_id: @post.id).all)
    end
  end

  describe "Requesting /forums/3/posts/2/comments (testing the before filters)" do
    include CommentsSpecHelper
  
    before(:each) do
      setup_mocks
      @comments = double('Comments')
      allow(@post_comments).to receive(:all).and_return(@comments)
    end
  
    def do_get
      get :index, params: { :forum_id => '3', :post_id => '2' }
    end
    
    it "should find the forum" do
      expect(Forum).to receive(:find).with('3').and_return(@forum)
      do_get
    end
  
    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
    end
  
    it "should find the post" do
      expect(@forum).to receive(:posts).and_return(@forum_posts)
      expect(@forum_posts).to receive(:find).with('2').and_return(@post)
      do_get
    end
  
    it "should assign the found post for the view" do
      do_get
      expect(assigns[:post]).to eq(@post)
    end
  
    it "should assign the post_comments association as the comments resource_service" do
      expect(@post).to receive(:comments).and_return(@post_comments)
      do_get
      expect(@controller.resource_service.service).to be(@post_comments)
    end
  end

  describe "Requesting /forums/3/posts/2/comments using GET" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comments = double('Comments')
      allow(@post_comments).to receive(:all).and_return(@comments)
    end
  
    def do_get
      get :index, params: { :forum_id => '3', :post_id => '2' }
    end
  
    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end

    it "should render index.rhtml" do
      do_get
      expect(response).to render_template(:index)
    end
  
    it "should find comments in post" do
      expect(@post_comments).to receive(:all).and_return(@comments)
      do_get
    end
  
    it "should assign the found comments for the view" do
      do_get
      expect(assigns[:comments]).to eq(@comments)
    end
  end

  describe "Requesting /forums/3/posts/3/comments/1 using GET" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('a post')
      allow(@post_comments).to receive(:find).and_return(@comment)
    end
  
    def do_get
      get :show, params: { :id => "1", :forum_id => '3', :post_id => '2' }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render show.rhtml" do
      do_get
      expect(response).to render_template(:show)
    end
  
    it "should find the comment requested" do
      expect(@post_comments).to receive(:find).with("1").and_return(@comment)
      do_get
    end
  
    it "should assign the found comment for the view" do
      do_get
      expect(assigns[:comment]).to eq(@comment)
    end
  end

  describe "Requesting /forums/3/posts/3/comments/new using GET" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('new Comment')
      allow(@post_comments).to receive(:build).and_return(@comment)
    end
  
    def do_get
      get :new, params: { :forum_id => '3', :post_id => '2' }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render new.rhtml" do
      do_get
      expect(response).to render_template(:new)
    end
  
    it "should build a new comment" do
      expect(@post_comments).to receive(:build).and_return(@comment)
      do_get
    end
  
    it "should not save the new comment" do
      expect(@comment).not_to receive(:save)
      do_get
    end
  
    it "should assign the new comment for the view" do
      do_get
      expect(assigns[:post]).to eq(@post)
    end
  end

  describe "Requesting /forums/3/posts/3/comments/1/edit using GET" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('Comment')
      allow(@post_comments).to receive(:find).and_return(@comment)
    end
 
    def do_get
      get :edit, params: { :id => "1", :forum_id => '3', :post_id => '2' }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render edit.rhtml" do
      do_get
      expect(response).to render_template(:edit)
    end
  
    it "should find the comment requested" do
      expect(@post_comments).to receive(:find).with("1").and_return(@comment)
      do_get
    end
  
    it "should assign the found comment for the view" do
      do_get
      expect(assigns(:comment)).to eq(@comment)
    end
  end

  describe "Requesting /forums/3/posts/3/comments using POST" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('Comment')
      allow(@comment).to receive(:save).and_return(true)
      allow(@comment).to receive(:to_param).and_return("1")
      allow(@post_comments).to receive(:build).and_return(@comment)
    end
  
    def do_post
      post :create, params: { :comment => {:name => 'Comment'}, :forum_id => '3', :post_id => '2' }
    end
  
    it "should build a new comment" do
      expect(@post_comments).to receive(:build) do |params|
        expect(params).to be_a(ActionController::Parameters)
        expect(params.permitted?).to be true
        expect(params.to_h).to eq('name' => 'Comment')
        @comment
      end
      do_post
    end

    it "should redirect to the new comment" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/3/posts/2/comments/1")
    end
  end

  describe "Requesting /forums/3/posts/3/comments/1 using PUT" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('Comment').as_null_object
      allow(@comment).to receive(:to_param).and_return("1")
      allow(@post_comments).to receive(:find).and_return(@comment)
    end
  
    def do_update
      put :update, params: { :id => "1", :forum_id => '3', :post_id => '2' }
    end
  
    it "should find the comment requested" do
      expect(@post_comments).to receive(:find).with("1").and_return(@comment)
      do_update
    end

    it "should update the found comment" do
      expect(@comment).to receive(:update).and_return(true)
      do_update
    end

    it "should assign the found comment for the view" do
      do_update
      expect(assigns(:comment)).to eq(@comment)
    end

    it "should redirect to the comment" do
      do_update
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/3/posts/2/comments/1")
    end
  end


  describe "Requesting /forums/3/posts/3/comments/1 using DELETE" do
    include CommentsSpecHelper

    before(:each) do
      setup_mocks
      @comment = double('Comment', :id => '1').as_null_object
      allow(@post_comments).to receive(:find).and_return(@comment)
      allow(@post_comments).to receive(:destroy)
    end
  
    def do_delete
      delete :destroy, params: { :id => "1", :forum_id => '3', :post_id => '2' }
    end

    it "should find and destroy the comment requested" do
      expect(@post_comments).to receive(:find).with("1").and_return(@comment)
      expect(@post_comments).to receive(:destroy).with("1")
      do_delete
      expect(assigns['comment']).to eq(@comment)
    end
  
    it "should redirect to the comments list" do
      do_delete
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/3/posts/2/comments")
    end
  end
end
