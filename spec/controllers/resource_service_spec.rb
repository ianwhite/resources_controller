require File.dirname(__FILE__) + '/../spec_helper'

context "resource_service in ForumsController" do
  controller_name :forums
  
  setup do
    @forum = Forum.create
    
    get :index
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new forum with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Forum
  end
  
  specify "should find @forum with find(@forum.id)" do
    resource = @resource_service.find(@forum.id)
    resource.should_be == @forum
  end

  specify "should find all forums with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Forum.find(:all)
  end
end

context "resource_service in ForumPostsController" do
  controller_name :forum_posts
  
  setup do
    @forum        = Forum.create
    @post         = Post.create :forum_id => @forum.id
    @other_forum  = Forum.create
    @other_post   = Post.create :forum_id => @other_forum.id
    
    get :index, :forum_id => @forum.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new post with @forum foreign key with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Post
    resource.forum_id.should == @forum.id
  end
  
  specify "should find @post with find(@post.id)" do
    resource = @resource_service.find(@post.id)
    resource.should_be == @post
  end
  
  specify "should raise RecordNotFound with find(@other_post.id)" do
    lambda{ @resource_service.find(@other_post.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only posts belonging to @forum with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Post.find(:all, :conditions => "forum_id = #{@forum.id}")
  end
end

context "resource_service in CommentsController" do
  controller_name :comments
  
  setup do
    @forum          = Forum.create
    @post           = Post.create :forum_id => @forum.id
    @comment        = Comment.create :post_id => @post.id
    @other_post     = Post.create :forum_id => @forum.id
    @other_comment  = Comment.create :post_id => @other_post.id
    
    get :index, :forum_id => @forum.id, :post_id => @post.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new comment with @post foreign key with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Comment
    resource.post_id.should == @post.id
  end
  
  specify "should find @comment with find(@comment.id)" do
    resource = @resource_service.find(@comment.id)
    resource.should_be == @comment
  end
  
  specify "should raise RecordNotFound with find(@other_post.id)" do
    lambda{ @resource_service.find(@other_comment.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only comments belonging to @post with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Comment.find(:all, :conditions => "post_id = #{@post.id}")
  end
end