require File.dirname(__FILE__) + '/../spec_helper'

module CommentsSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    @forum_posts = mock('Assoc: forum_posts')
    @forum.stub!(:posts).and_return(@forum_posts)
    @forum.stub!(:to_param).and_return(3)
    
    @post = mock('Post')
    @post_comments = mock('Assoc: post_comments')
    @post.stub!(:comments).and_return(@post_comments)
    @post.stub!(:to_param).and_return(2)
        
    Forum.stub!(:find).and_return(@forum)
    @forum_posts.stub!(:find).and_return(@post)
  end
end

context "Requesting /forums/3/posts/2/something (testing the before filters)" do
  include CommentsSpecHelper
  controller_name :comments
  
  setup do
    setup_mocks
  end
  
  def do_get
    get :something, :forum_id => '3', :post_id => '2'
  end
    
  specify "should find the forum" do
    Forum.should_receive(:find).with('3').and_return(@forum)
    do_get
  end
  
  specify "should assign the found forum for the view" do
    do_get
    assigns[:forum].should_be @forum
  end
  
  specify "should find the post" do
    @forum.should_receive(:posts).and_return(@forum_posts)
    @forum_posts.should_receive(:find).with('2').and_return(@post)
    do_get
  end
  
  specify "should assign the found post for the view" do
    do_get
    assigns[:post].should_be @post
  end
  
  specify "should assign the post_comments association as the comments resource_service" do
    @post.should_receive(:comments).and_return(@post_comments)
    do_get
    @controller.resource_service.should_be @post_comments
  end
end

context "Requesting /forums/3/posts/2/comments using GET" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comments = mock('Comments')
    @post_comments.stub!(:find).and_return(@comments)
  end
  
  def do_get
    get :index, :forum_id => '3', :post_id => '2'
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should render index.rhtml" do
    controller.should_render :index
    do_get
  end
  
  specify "should find comments in post" do
    @post_comments.should_receive(:find).with(:all).and_return(@comments)
    do_get
  end
  
  specify "should assign the found comments for the view" do
    do_get
    assigns[:comments].should_be @comments
  end
end

context "Requesting /forums/3/posts/3/comments/1 using GET" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('a post')
    @post_comments.stub!(:find).and_return(@comment)
  end
  
  def do_get
    get :show, :id => "1", :forum_id => '3', :post_id => '2'
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render show.rhtml" do
    controller.should_render :show
    do_get
  end
  
  specify "should find the comment requested" do
    @post_comments.should_receive(:find).with("1").and_return(@comment)
    do_get
  end
  
  specify "should assign the found comment for the view" do
    do_get
    assigns[:comment].should_be @comment
  end
end

context "Requesting /forums/3/posts/3/comments/new using GET" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('new Comment')
    @post_comments.stub!(:new).and_return(@comment)
  end
  
  def do_get
    get :new, :forum_id => '3', :post_id => '2'
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render new.rhtml" do
    controller.should_render :new
    do_get
  end
  
  specify "should create a new comment" do
    @post_comments.should_receive(:new).and_return(@comment)
    do_get
  end
  
  specify "should not save the new comment" do
    @comment.should_not_receive(:save)
    do_get
  end
  
  specify "should assign the new comment for the view" do
    do_get
    assigns[:post].should_be @post
  end
end

context "Requesting /forums/3/posts/3/comments/1;edit using GET" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('Comment')
    @post_comments.stub!(:find).and_return(@comment)
  end
 
  def do_get
    get :edit, :id => "1", :forum_id => '3', :post_id => '2'
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render edit.rhtml" do
    do_get
    controller.should_render :edit
  end
  
  specify "should find the comment requested" do
    @post_comments.should_receive(:find).with("1").and_return(@comment)
    do_get
  end
  
  specify "should assign the found comment for the view" do
    do_get
    assigns(:comment).should_be @comment
  end
end

context "Requesting /forums/3/posts/3/comments using POST" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('Comment')
    @comment.stub!(:save).and_return(true)
    @comment.stub!(:to_param).and_return(1)
    @post_comments.stub!(:new).and_return(@comment)
  end
  
  def do_post
    post :create, :comment => {:name => 'Comment'}, :forum_id => '3', :post_id => '2'
  end
  
  specify "should create a new comment" do
    @post_comments.should_receive(:new).with({'name' => 'Comment'}).and_return(@comment)
    do_post
  end

  specify "should redirect to the new comment" do
    do_post
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/3/posts/2/comments/1"
  end
end

context "Requesting /forums/3/posts/3/comments/1 using PUT" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('Comment', :null_object => true)
    @comment.stub!(:to_param).and_return(1)
    @post_comments.stub!(:find).and_return(@comment)
  end
  
  def do_update
    put :update, :id => "1", :forum_id => '3', :post_id => '2'
  end
  
  specify "should find the comment requested" do
    @post_comments.should_receive(:find).with("1").and_return(@comment)
    do_update
  end

  specify "should update the found comment" do
    @comment.should_receive(:update_attributes)
    do_update
  end

  specify "should assign the found comment for the view" do
    do_update
    assigns(:comment).should_be @comment
  end

  specify "should redirect to the comment" do
    do_update
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/3/posts/2/comments/1"
  end
end

context "Requesting /forums/3/posts/3/comments/1 using DELETE" do
  include CommentsSpecHelper
  controller_name :comments

  setup do
    setup_mocks
    @comment = mock('Comment', :null_object => true)
    @post_comments.stub!(:find).and_return(@comment)
  end
  
  def do_delete
    delete :destroy, :id => "1", :forum_id => '3', :post_id => '2'
  end

  specify "should find the comment requested" do
    @post_comments.should_receive(:find).with("1").and_return(@comment)
    do_delete
  end
  
  specify "should call destroy on the found comment" do
    @comment.should_receive(:destroy)
    do_delete
  end
  
  specify "should redirect to the comments list" do
    do_delete
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/3/posts/2/comments"
  end
end