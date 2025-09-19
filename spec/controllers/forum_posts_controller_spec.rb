require 'spec_helper'

module ForumPostsSpecHelper
  def setup_mocks
    @forum = double('Forum')
    @forum_posts = double('Assoc: forum_posts')
    allow(@forum).to receive(:posts).and_return(@forum_posts)
    allow(@forum).to receive(:to_param).and_return("2")
    
    allow(Forum).to receive(:find).and_return(@forum)
  end
end

describe ForumPostsController do
  describe "Routing shortcuts for ForumPosts (forums/2/posts/1) should map" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('Post')
      allow(@post).to receive(:to_param).and_return('1')
      allow(@forum_posts).to receive(:find).and_return(@post)
  
      get :show, params: { :forum_id => "2", :id => "1" }
    end
  
    it "resources_path to /forums/2/posts" do
      expect(controller.resources_path).to eq('/forums/2/posts')
    end

    it "resource_path to /forums/2/posts/1" do
      expect(controller.resource_path).to eq('/forums/2/posts/1')
    end
  
    it "resource_path(9) to /forums/2/posts/9" do
      expect(controller.resource_path(9)).to eq('/forums/2/posts/9')
    end

    it "edit_resource_path to /forums/2/posts/1/edit" do
      expect(controller.edit_resource_path).to eq('/forums/2/posts/1/edit')
    end
  
    it "edit_resource_path(9) to /forums/2/posts/9/edit" do
      expect(controller.edit_resource_path(9)).to eq('/forums/2/posts/9/edit')
    end
  
    it "new_resource_path to /forums/2/posts/new" do
      expect(controller.new_resource_path).to eq('/forums/2/posts/new')
    end
  
    it "resource_tags_path to /forums/2/posts/1/tags" do
      expect(controller.resource_tags_path).to eq("/forums/2/posts/1/tags")
    end

    it "resource_tags_path(9) to /forums/2/posts/9/tags" do
      expect(controller.resource_tags_path(9)).to eq("/forums/2/posts/9/tags") 
    end
  
    it "resource_tag_path(5) to /forums/2/posts/1/tags/5" do
      expect(controller.resource_tag_path(5)).to eq("/forums/2/posts/1/tags/5")
    end
  
    it "resource_tag_path(9,5) to /forums/2/posts/9/tags/5" do
      expect(controller.resource_tag_path(9,5)).to eq("/forums/2/posts/9/tags/5")
    end
  
    it "enclosing_resource_path to /forums/2" do
      expect(controller.enclosing_resource_path).to eq('/forums/2')
    end
  
    it "enclosing_resource_path(9) to /forums/9" do
      expect(controller.enclosing_resource_path(9)).to eq('/forums/9')
    end
  
    it "enclosing_resources_path to /forums" do
      expect(controller.enclosing_resources_path).to eq('/forums')
    end
  
    it "new_enclosing_resource_path to /forums/new" do
      expect(controller.new_enclosing_resource_path).to eq('/forums/new')
    end
  
    it "enclosing_resource_tags_path to /forums/2/tags" do
      expect(controller.enclosing_resource_tags_path).to eq('/forums/2/tags')
    end

    it "enclosing_resource_tag_path(9) to /forums/2/tags/9" do
      expect(controller.enclosing_resource_tag_path(9)).to eq('/forums/2/tags/9')
    end

    it "enclosing_resource_tag_path(8,9) to /forums/8/tags/9" do
      expect(controller.enclosing_resource_tag_path(8,9)).to eq('/forums/8/tags/9')
    end
  end

  describe ForumPostsController, " errors" do
  
    it "should raise ResourceMismatch for /posts" do
      expect{ get :index }.to raise_error(ResourcesController::ResourceMismatch)
    end

    it "should raise ResourceMismatch, when route does not contain the resource segment" do
      expect{ get :index, params: { :foo_id => 1} }.to raise_error(ResourcesController::ResourceMismatch)
    end
  end

  describe "resource_service in ForumPostsController" do
  
    before(:each) do
      @forum        = Forum.create
      @post         = Post.create :forum_id => @forum.id
      @other_forum  = Forum.create
      @other_post   = Post.create :forum_id => @other_forum.id
    
      get :index, params: { :forum_id => @forum.id }
      @resource_service = controller.send :resource_service
    end
  
    it "should build new post with @forum foreign key with new" do
      resource = @resource_service.new
      expect(resource).to be_kind_of(Post)
      expect(resource.forum_id).to eq(@forum.id)
    end
  
    it "should find @post with find(@post.id)" do
      resource = @resource_service.find(@post.id)
      expect(resource).to eq(@post)
    end
  
    it "should raise RecordNotFound with find(@other_post.id)" do
      expect{ @resource_service.find(@other_post.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should find only posts belonging to @forum with .all" do
      resources = @resource_service.all
      expect(resources).to eq(Post.where(forum_id: @forum.id).all)
    end
  end

  describe ForumPostsController, ' order of before_filters' do
    before do
      @forum        = Forum.create
      get :index, params: { :forum_id => @forum.id }
    end
  
    it { expect(@controller.filter_trace).to eq([:abstract, :posts, :load_enclosing, :forum_posts]) }
  end

  describe "Requesting /forums/2/posts (testing the before filters)" do
    include ForumPostsSpecHelper
  
    before(:each) do
      setup_mocks
      @posts = double('Posts')
      allow(@forum_posts).to receive(:order).and_return(@posts)
    end
  
    def do_get
      get :index, params: { :forum_id => '2' }
    end
    
    it "should find the forum" do
      expect(Forum).to receive(:find).with('2').and_return(@forum)
      do_get
    end
  
    it "should assign the form as other_name_for_forum" do
      do_get
      expect(assigns[:other_name_for_forum]).to eq(assigns[:forum])
    end
  
    it "should assign the found forum for the view" do
      do_get
      expect(assigns[:forum]).to eq(@forum)
    end
  
    it "should assign the forum_posts association as the posts resource_service" do
      expect(@forum).to receive(:posts).and_return(@forum_posts)
      do_get
      expect(@controller.resource_service.service).to be(@forum_posts)
    end 
  end

  describe "Requesting /forums/2/posts using GET" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @posts = double('Posts')
      allow(@forum_posts).to receive(:order).and_return(@posts)
    end
  
    def do_get
      get :index, params: { :forum_id => '2' }
    end
  
    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end

    it "should render index.rhtml" do
      do_get
      expect(response).to render_template(:index)
    end
  
    it "should find all posts, in reverse order (because of AbstractPostsController)" do
      expect(@forum_posts).to receive(:order).with('id DESC').and_return(@posts)
      do_get
    end
  
    it "should assign the found posts for the view" do
      do_get
      expect(assigns[:posts]).to eq(@posts)
    end
  end

  describe "Requesting /forums/2/posts/1 using GET" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('a post')
      allow(@forum_posts).to receive(:find).and_return(@post)
    end
  
    def do_get
      get :show, params: { :id => "1", :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render show.rhtml" do
      do_get
      expect(response).to render_template(:show)
    end
  
    it "should find the thing requested" do
      expect(@forum_posts).to receive(:find).with("1").and_return(@post)
      do_get
    end
  
    it "should assign the found thing for the view" do
      do_get
      expect(assigns[:post]).to eq(@post)
    end
  end

  describe "Requesting /forums/2/posts/new using GET" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('new Post')
      allow(@forum_posts).to receive(:build).and_return(@post)
    end
  
    def do_get
      get :new, params: { :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render new.rhtml" do
      do_get
      expect(response).to render_template(:new)
    end
  
    it "should build an new thing" do
      expect(@forum_posts).to receive(:build).and_return(@post)
      do_get
    end
  
    it "should not save the new thing" do
      expect(@post).not_to receive(:save)
      do_get
    end
  
    it "should assign the new thing for the view" do
      do_get
      expect(assigns[:post]).to eq(@post)
    end
  end

  describe "Requesting /forums/2/posts/1/edit using GET" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('Post')
      allow(@forum_posts).to receive(:find).and_return(@post)
    end
 
    def do_get
      get :edit, params: { :id => "1", :forum_id => "2" }
    end

    it "should be successful" do
      do_get
      expect(response).to have_http_status(:ok)
    end
  
    it "should render edit.rhtml" do
      do_get
      expect(response).to render_template(:edit)
    end
  
    it "should find the thing requested" do
      expect(@forum_posts).to receive(:find).with("1").and_return(@post)
      do_get
    end
  
    it "should assign the found Thing for the view" do
      do_get
      expect(assigns(:post)).to equal(@post)
    end
  end

  describe "Requesting /forums/2/posts using POST" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('Post')
      allow(@post).to receive(:save).and_return(true)
      allow(@post).to receive(:to_param).and_return("1")
      allow(@forum_posts).to receive(:build).and_return(@post)
    end
  
    def do_post
      post :create, params: { :post => {:name => 'Post'}, :forum_id => "2" }
    end
  
    it "should build a new post" do
      expect(@forum_posts).to receive(:build) do |params|
        expect(params).to be_a(ActionController::Parameters)
        expect(params.permitted?).to be true
        expect(params.to_h).to eq('name' => 'Post')
        @post
      end
      do_post
    end

    it "should attempt to save the new post" do
      expect(@post).to receive(:save).and_return(true)
      do_post
    end
  
    it "should redirect to the new post.save == true" do
      do_post
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/2/posts/1")
    end
  
    it "should render new when post.save == false" do
      allow(@post).to receive(:save).and_return(false)
      do_post
      expect(response).to render_template(:new)
    end
  end

  describe "Requesting /forums/2/posts/1 using PUT" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('Post').as_null_object
      allow(@post).to receive(:to_param).and_return("1")
      allow(@forum_posts).to receive(:find).and_return(@post)
    end
  
    def do_update
      put :update, params: { :id => "1", :forum_id => "2" }
    end
  
    it "should find the post requested" do
      expect(@forum_posts).to receive(:find).with("1").and_return(@post)
      do_update
    end

    it "should update the found post" do
      expect(@post).to receive(:update)
      do_update
    end

    it "should assign the found post for the view" do
      do_update
      expect(assigns(:post)).to eq(@post)
    end

    it "should redirect to the post" do
      do_update
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/2/posts/1")
    end
  end

  describe "Requesting /forums/2/posts/1 using DELETE" do
    include ForumPostsSpecHelper

    before(:each) do
      setup_mocks
      @post = double('Post').as_null_object
      allow(@forum_posts).to receive(:find).and_return(@post)
      allow(@forum_posts).to receive(:destroy)
    end
  
    def do_delete
      delete :destroy, params: { :id => "1", :forum_id => "2" }
    end

    it "should find and destroy the post requested" do
      expect(@forum_posts).to receive(:find).with("1").and_return(@post)
      expect(@forum_posts).to receive(:destroy).with("1")
      do_delete
      expect(assigns['post']).to eq(@post)
    end
  
    it "should redirect to the things list" do
      do_delete
      expect(response).to be_redirect
      expect(response.redirect_url).to eq("http://test.host/forums/2/posts")
    end
  end
end
