require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module TagsViaForumPostSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    Forum.stub!(:find).and_return(@forum)
    @forum.stub!(:to_param).and_return('1')
    @forum_posts = mock('forum_posts assoc')
    @forum.stub!(:posts).and_return(@forum_posts)
    
    @post = mock('Post')
    @forum_posts.stub!(:find).and_return(@post)
    @post.stub!(:to_param).and_return('2')
    @post_tags = mock('post_tags assoc')
    @post.stub!(:tags).and_return(@post_tags)
  end
end

context "Routing shortcuts for Tags via Forum and Post (forums/1/posts/2/tags/3) should map" do
  include TagsViaForumPostSpecHelper
  controller_name :tags
  
  setup do
    setup_mocks
    @tag = mock('Tag')
    @tag.stub!(:to_param).and_return('3')
    @post_tags.stub!(:find).and_return(@tag)
    
    get :show, :forum_id => "1", :post_id => "2", :id => "3"
  end
  
  specify "resources_path to /forums/1/posts/2/tags" do
    controller.resources_path.should == '/forums/1/posts/2/tags'
  end

  specify "resource_path to /forums/1/posts/2/tags/3" do
    controller.resource_path.should == '/forums/1/posts/2/tags/3'
  end
  
  specify "resource_path(9) to /forums/1/posts/2/tags/9" do
    controller.resource_path(9).should == '/forums/1/posts/2/tags/9'
  end

  specify "edit_resource_path to /forums/1/posts/2/tags/3;edit" do
    controller.edit_resource_path.should == '/forums/1/posts/2/tags/3;edit'
  end
  
  specify "edit_resource_path(9) to /forums/1/posts/2/tags/9;edit" do
    controller.edit_resource_path(9).should == '/forums/1/posts/2/tags/9;edit'
  end
  
  specify "new_resource_path to /forums/1/posts/2/tags/new" do
    controller.new_resource_path.should == '/forums/1/posts/2/tags/new'
  end
end

context "resource_service in TagsController via Forum and Post" do
  controller_name :tags
  
  setup do
    @forum       = Forum.create
    @post        = Post.create :forum_id => @forum.id
    @tag         = Tag.create :taggable_id => @post.id, :taggable_type => 'Post'
    @other_post  = Post.create :forum_id => @forum.id
    @other_tag   = Tag.create :taggable_id => @other_post.id, :taggable_type => 'Post'
    
    get :index, :forum_id => @forum.id, :post_id => @post.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new tag with @post fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Tag
    resource.taggable_id.should == @post.id
    resource.taggable_type.should == 'Post'
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
    resources.should_be == Tag.find(:all, :conditions => "taggable_id = #{@post.id} AND taggable_type = 'Post'")
  end
end

context "Requesting /forums/1/posts/2/tags using GET" do
  include TagsViaForumPostSpecHelper
  controller_name :tags

  setup do
    setup_mocks
    @tags = mock('Tags')
    @post_tags.stub!(:find).and_return(@tags)
  end
  
  def do_get
    get :index, :forum_id => 1, :post_id => 2
  end

  specify "should find the forum" do
    Forum.should_receive(:find).with('1').and_return(@forum)
    do_get
  end
  
  specify "should find the post" do
    @forum_posts.should_receive(:find).with('2').and_return(@post)
    do_get
  end

  specify "should assign the found post as :taggable for the view" do
    do_get
    assigns[:taggable].should_be @post
  end

  specify "should assign the post_tags association as the tags resource_service" do
    @post.should_receive(:tags).and_return(@post_tags)
    do_get
    @controller.resource_service.service.should_be @post_tags
  end 
end