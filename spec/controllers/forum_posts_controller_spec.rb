require File.dirname(__FILE__) + '/../spec_helper'

module ForumPostsSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    @forum_posts = mock('Assoc: forum_posts')
    @forum.stub!(:posts).and_return(@forum_posts)
    @forum.stub!(:to_param).and_return("2")
    
    Forum.stub!(:find).and_return(@forum)
  end
end

context "Requesting /forums/2/something (testing the before filters)" do
  include ForumPostsSpecHelper
  controller_name :forum_posts
  
  setup do
    setup_mocks
  end
  
  def do_get
    get :something, :forum_id => '2'
  end
    
  specify "should find the forum" do
    Forum.should_receive(:find).with('2').and_return(@forum)
    do_get
  end
  
  specify "should assign the found forum for the view" do
    do_get
    assigns[:forum].should_be @forum
  end
  
  specify "should assign the forum_posts association as the posts resource_service" do
    @forum.should_receive(:posts).and_return(@forum_posts)
    do_get
    @controller.resource_service.should_be @forum_posts
  end 
end

context "Requesting /forums/2/posts using GET" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @posts = mock('Posts')
    @forum_posts.stub!(:find).and_return(@posts)
  end
  
  def do_get
    get :index, :forum_id => '2'
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should render index.rhtml" do
    controller.should_render :index
    do_get
  end
  
  specify "should find all posts" do
    @forum_posts.should_receive(:find).with(:all).and_return(@posts)
    do_get
  end
  
  specify "should assign the found posts for the view" do
    do_get
    assigns[:posts].should_be @posts
  end
end

context "Requesting /forums/2/posts/1 using GET" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('a post')
    @forum_posts.stub!(:find).and_return(@post)
  end
  
  def do_get
    get :show, :id => "1", :forum_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render show.rhtml" do
    controller.should_render :show
    do_get
  end
  
  specify "should find the thing requested" do
    @forum_posts.should_receive(:find).with("1").and_return(@post)
    do_get
  end
  
  specify "should assign the found thing for the view" do
    do_get
    assigns[:post].should_be @post
  end
end

context "Requesting /forums/2/posts/new using GET" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('new Post')
    @forum_posts.stub!(:new).and_return(@post)
  end
  
  def do_get
    get :new, :forum_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render new.rhtml" do
    controller.should_render :new
    do_get
  end
  
  specify "should create an new thing" do
    @forum_posts.should_receive(:new).and_return(@post)
    do_get
  end
  
  specify "should not save the new thing" do
    @post.should_not_receive(:save)
    do_get
  end
  
  specify "should assign the new thing for the view" do
    do_get
    assigns[:post].should_be @post
  end
end

context "Requesting /forums/2/posts/1;edit using GET" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('Post')
    @forum_posts.stub!(:find).and_return(@post)
  end
 
  def do_get
    get :edit, :id => "1", :forum_id => "2"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render edit.rhtml" do
    do_get
    controller.should_render :edit
  end
  
  specify "should find the thing requested" do
    @forum_posts.should_receive(:find).with("1").and_return(@post)
    do_get
  end
  
  specify "should assign the found Thing for the view" do
    do_get
    assigns(:post).should_equal @post
  end
end

context "Requesting /forums/2/posts using POST" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('Post')
    @post.stub!(:save).and_return(true)
    @post.stub!(:to_param).and_return("1")
    @forum_posts.stub!(:new).and_return(@post)
  end
  
  def do_post
    post :create, :post => {:name => 'Post'}, :forum_id => "2"
  end
  
  specify "should create a new post" do
    @forum_posts.should_receive(:new).with({'name' => 'Post'}).and_return(@post)
    do_post
  end

  specify "should redirect to the new post" do
    do_post
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/2/posts/1"
  end
end

context "Requesting /forums/2/posts/1 using PUT" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('Post', :null_object => true)
    @post.stub!(:to_param).and_return("1")
    @forum_posts.stub!(:find).and_return(@post)
  end
  
  def do_update
    put :update, :id => "1", :forum_id => "2"
  end
  
  specify "should find the post requested" do
    @forum_posts.should_receive(:find).with("1").and_return(@post)
    do_update
  end

  specify "should update the found post" do
    @post.should_receive(:update_attributes)
    do_update
  end

  specify "should assign the found post for the view" do
    do_update
    assigns(:post).should_be @post
  end

  specify "should redirect to the post" do
    do_update
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/2/posts/1"
  end
end

context "Requesting /forums/2/posts/1 using DELETE" do
  include ForumPostsSpecHelper
  controller_name :forum_posts

  setup do
    setup_mocks
    @post = mock('Post', :null_object => true)
    @forum_posts.stub!(:find).and_return(@post)
  end
  
  def do_delete
    delete :destroy, :id => "1", :forum_id => "2"
  end

  specify "should find the post requested" do
    @forum_posts.should_receive(:find).with("1").and_return(@post)
    do_delete
  end
  
  specify "should call destroy on the found thing" do
    @post.should_receive(:destroy)
    do_delete
  end
  
  specify "should redirect to the things list" do
    do_delete
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/2/posts"
  end
end