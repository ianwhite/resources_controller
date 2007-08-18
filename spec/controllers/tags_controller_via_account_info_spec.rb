require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

module TagsViaAccountInfoHelper
  def setup_mocks
    @current_user = mock('user')
    @current_user.stub!(:id).and_return('1')
    User.stub!(:find).and_return(@current_user)
    @info = mock('info')
    @info.stub!(:id).and_return('3')
    @current_user.stub!(:info).and_return(@info)
    @info_tags = mock('info_tags')
    @info.stub!(:tags).and_return(@info_tags)
    @controller.instance_variable_set('@current_user', @current_user)
  end
end

describe "Routing shortcuts for Tags via account info (/account/info/) should map" do
  include TagsViaAccountInfoHelper
  controller_name :tags
  
  before(:each) do
    setup_mocks
    @tag = mock('Tag')
    @tag.stub!(:to_param).and_return('2')
    @info_tags.stub!(:find).and_return(@tag)
    
    @controller.stub!(:recognized_route).and_return(ActionController::Routing::Routes.named_routes[:account_info_tag])
    get :show, :id => 2
  end
  
  it "resources_path to /account/info/tags" do
    controller.resources_path.should == '/account/info/tags'
  end

  it "resource_path to /account/info/tags/2" do
    controller.resource_path.should == '/account/info/tags/2'
  end
  
  it "resource_path(9) to /account/info/tags/9" do
    controller.resource_path(9).should == '/account/info/tags/9'
  end

  it "edit_resource_path to /account/info/tags/2/edit" do
    controller.edit_resource_path.should == '/account/info/tags/2/edit'
  end
  
  it "edit_resource_path(9) to /account/info/tags/9/edit" do
    controller.edit_resource_path(9).should == '/account/info/tags/9/edit'
  end
  
  it "new_resource_path to /account/info/tags/new" do
    controller.new_resource_path.should == '/account/info/tags/new'
  end
  
  it "enclosing_resource_path to /account/info" do
    controller.enclosing_resource_path.should == "/account/info"
  end
end

#describe "resource_service in TagsController via Forum" do
#  controller_name :tags
#  
#  before(:each) do
#    @forum       = Forum.create
#    @tag         = Tag.create :taggable_id => @forum.id, :taggable_type => 'Forum'
#    @other_forum = Forum.create
#    @other_tag   = Tag.create :taggable_id => @other_forum.id, :taggable_type => 'Forum'
#    
#    get :index, :forum_id => @forum.id
#    @resource_service = controller.send :resource_service
#  end
#  
#  it "should build new tag with @forum fk and type with new" do
#    resource = @resource_service.new
#    resource.should be_kind_of(Tag)
#    resource.taggable_id.should == @forum.id
#    resource.taggable_type.should == 'Forum'
#  end
#  
#  it "should find @tag with find(@tag.id)" do
#    resource = @resource_service.find(@tag.id)
#    resource.should == @tag
#  end
#  
#  it "should raise RecordNotFound with find(@other_tag.id)" do
#    lambda{ @resource_service.find(@other_tag.id) }.should raise_error(ActiveRecord::RecordNotFound)
#  end
#
#  it "should find only tags belonging to @forum with find(:all)" do
#    resources = @resource_service.find(:all)
#    resources.should be == Tag.find(:all, :conditions => "taggable_id = #{@forum.id} AND taggable_type = 'Forum'")
#  end
#end
#
#describe "Requesting /forums/1/tags using GET" do
#  include TagsViaForumSpecHelper
#  controller_name :tags
#
#  before(:each) do
#    setup_mocks
#    @tags = mock('Tags')
#    @forum_tags.stub!(:find).and_return(@tags)
#  end
#  
#  def do_get
#    get :index, :forum_id => 1
#  end
#
#  it "should find the forum" do
#    Forum.should_receive(:find).with('1').and_return(@forum)
#    do_get
#  end
#
#  it "should assign the found forum as :taggable for the view" do
#    do_get
#    assigns[:taggable].should == @forum
#  end
#
#  it "should assign the forum_tags association as the tags resource_service" do
#    @forum.should_receive(:tags).and_return(@forum_tags)
#    do_get
#    @controller.resource_service.should == @forum_tags
#  end 
#end