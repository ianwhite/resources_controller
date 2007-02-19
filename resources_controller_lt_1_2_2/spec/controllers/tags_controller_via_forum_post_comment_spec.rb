require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module TagsViaForumPostCommentSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    Forum.stub!(:find).and_return(@forum)
    @forum.stub!(:to_param).and_return('1')
    @forum_posts = mock('forum_posts assoc')
    @forum.stub!(:posts).and_return(@forum_posts)
    
    @post = mock('Post')
    @forum_posts.stub!(:find).and_return(@post)
    @post.stub!(:to_param).and_return('2')
    @post_comments = mock('post_comments assoc')
    @post.stub!(:comments).and_return(@post_comments)
    
    @comment = mock('Comment')
    @post_comments.stub!(:find).and_return(@comment)
    @comment.stub!(:to_param).and_return('3')
    @comment_tags = mock('comment_tags assoc')
    @comment.stub!(:tags).and_return(@comment_tags)
  end
end

context "Routing shortcuts for Tags via Forum, Post and Comment (forums/1/posts/2/comments/3tags/4) should map" do
  include TagsViaForumPostCommentSpecHelper
  controller_name :tags
  
  setup do
    setup_mocks
    @tag = mock('Tag')
    @tag.stub!(:to_param).and_return('4')
    @comment_tags.stub!(:find).and_return(@tag)
    
    get :show, :forum_id => "1", :post_id => "2", :comment_id => '3', :id => "4"
  end
  
  specify "resources_path to /forums/1/posts/2/comments/3/tags" do
    controller.resources_path.should == '/forums/1/posts/2/comments/3/tags'
  end

  specify "resource_path to /forums/1/posts/2/comments/3/tags/4" do
    controller.resource_path.should == '/forums/1/posts/2/comments/3/tags/4'
  end
  
  specify "resource_path(9) to /forums/1/posts/2/comments/3/tags/9" do
    controller.resource_path(9).should == '/forums/1/posts/2/comments/3/tags/9'
  end

  specify "edit_resource_path to /forums/1/posts/2/comments/3/tags/4;edit" do
    controller.edit_resource_path.should == '/forums/1/posts/2/comments/3/tags/4;edit'
  end
  
  specify "edit_resource_path(9) to /forums/1/posts/2/comments/3/tags/9;edit" do
    controller.edit_resource_path(9).should == '/forums/1/posts/2/comments/3/tags/9;edit'
  end
  
  specify "new_resource_path to /forums/1/posts/2/comments/3/tags/new" do
    controller.new_resource_path.should == '/forums/1/posts/2/comments/3/tags/new'
  end
end

context "resource_service in TagsController via Forum, Post and Comment" do
  controller_name :tags
  
  setup do
    @forum         = Forum.create
    @post          = Post.create :forum_id => @forum.id
    @comment       = Comment.create :post_id => @post.id
    @tag           = Tag.create :taggable_id => @comment.id, :taggable_type => 'Comment'
    @other_comment = Comment.create :post_id => @forum.id
    @other_tag     = Tag.create :taggable_id => @other_comment.id, :taggable_type => 'Comment'
    
    get :index, :forum_id => @forum.id, :post_id => @post.id, :comment_id => @comment.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new tag with @comment fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Tag
    resource.taggable_id.should == @comment.id
    resource.taggable_type.should == 'Comment'
  end
  
  specify "should find @tag with find(@tag.id)" do
    resource = @resource_service.find(@tag.id)
    resource.should_be == @tag
  end
  
  specify "should raise RecordNotFound with find(@other_tag.id)" do
    lambda{ @resource_service.find(@other_tag.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only tags belonging to @post with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Tag.find(:all, :conditions => "taggable_id = #{@comment.id} AND taggable_type = 'Comment'")
  end
end

context "Requesting /forums/1/posts/2/tags using GET" do
  include TagsViaForumPostCommentSpecHelper
  controller_name :tags

  setup do
    setup_mocks
    @tags = mock('Tags')
    @comment_tags.stub!(:find).and_return(@tags)
  end
  
  def do_get
    get :index, :forum_id => 1, :post_id => 2, :comment_id => 3
  end

  specify "should find the forum" do
    Forum.should_receive(:find).with('1').and_return(@forum)
    do_get
  end
  
  specify "should find the post" do
    @forum_posts.should_receive(:find).with('2').and_return(@post)
    do_get
  end

  specify "should find the comment" do
    @post_comments.should_receive(:find).with('3').and_return(@comment)
    do_get
  end

  specify "should assign the found comment as :taggable for the view" do
    do_get
    assigns[:taggable].should_be @comment
  end

  specify "should assign the comment_tags association as the tags resource_service" do
    @comment.should_receive(:tags).and_return(@comment_tags)
    do_get
    @controller.resource_service.should_be @comment_tags
  end 
end