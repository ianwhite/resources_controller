require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module TagsViaForumSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    @forum_tags = mock('forum_tags assoc')
    Forum.stub!(:find).and_return(@forum)
    @forum.stub!(:tags).and_return(@forum_tags)
    @forum.stub!(:to_param).and_return('1')
  end
end

context "Routing shortcuts for Tags via Forum (forums/1/tags/2) should map" do
  include TagsViaForumSpecHelper
  controller_name :tags
  
  setup do
    setup_mocks
    @tag = mock('Tag')
    @tag.stub!(:to_param).and_return('2')
    @forum_tags.stub!(:find).and_return(@tag)
    
    get :show, :forum_id => "1", :id => "2"
  end
  
  specify "resources_path to /forums/1/tags" do
    controller.resources_path.should == '/forums/1/tags'
  end

  specify "resource_path to /forums/1/tags/2" do
    controller.resource_path.should == '/forums/1/tags/2'
  end
  
  specify "resource_path(9) to /forums/1/tags/9" do
    controller.resource_path(9).should == '/forums/1/tags/9'
  end

  specify "edit_resource_path to /forums/1/tags/2;edit" do
    controller.edit_resource_path.should == '/forums/1/tags/2;edit'
  end
  
  specify "edit_resource_path(9) to /forums/1/tags/9;edit" do
    controller.edit_resource_path(9).should == '/forums/1/tags/9;edit'
  end
  
  specify "new_resource_path to /forums/1/tags/new" do
    controller.new_resource_path.should == '/forums/1/tags/new'
  end
end

context "resource_service in TagsController via Forum" do
  controller_name :tags
  
  setup do
    @forum       = Forum.create
    @tag         = Tag.create :taggable_id => @forum.id, :taggable_type => 'Forum'
    @other_forum = Forum.create
    @other_tag   = Tag.create :taggable_id => @other_forum.id, :taggable_type => 'Forum'
    
    get :index, :forum_id => @forum.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new tag with @forum fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Tag
    resource.taggable_id.should == @forum.id
    resource.taggable_type.should == 'Forum'
  end
  
  specify "should find @tag with find(@tag.id)" do
    resource = @resource_service.find(@tag.id)
    resource.should_be == @tag
  end
  
  specify "should raise RecordNotFound with find(@other_tag.id)" do
    lambda{ @resource_service.find(@other_tag.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only tags belonging to @forum with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Tag.find(:all, :conditions => "taggable_id = #{@forum.id} AND taggable_type = 'Forum'")
  end
end

context "Requesting /forums/1/tags using GET" do
  include TagsViaForumSpecHelper
  controller_name :tags

  setup do
    setup_mocks
    @tags = mock('Tags')
    @forum_tags.stub!(:find).and_return(@tags)
  end
  
  def do_get
    get :index, :forum_id => 1
  end

  specify "should find the forum" do
    Forum.should_receive(:find).with('1').and_return(@forum)
    do_get
  end

  specify "should assign the found forum as :taggable for the view" do
    do_get
    assigns[:taggable].should_be @forum
  end

  specify "should assign the forum_tags association as the tags resource_service" do
    @forum.should_receive(:tags).and_return(@forum_tags)
    do_get
    @controller.resource_service.should_be @forum_tags
  end 
end