require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

module InterestsViaForumSpecHelper
  def setup_mocks
    @forum = mock('Forum')
    @forum_interests = mock('forum_interests assoc')
    Forum.stub!(:find).and_return(@forum)
    @forum.stub!(:interests).and_return(@forum_interests)
    @forum.stub!(:to_param).and_return('1')
  end
end

context "Routing shortcuts for Interests via Forum (forums/1/interests/2) should map" do
  include InterestsViaForumSpecHelper
  controller_name :interests
  
  setup do
    setup_mocks
    @interest = mock('Interest')
    @interest.stub!(:to_param).and_return('2')
    @forum_interests.stub!(:find).and_return(@interest)
    
    get :show, :forum_id => "1", :id => "2"
  end
  
  specify "resources_path to /forums/1/interests" do
    controller.resources_path.should == '/forums/1/interests'
  end

  specify "resource_path to /forums/1/interests/2" do
    controller.resource_path.should == '/forums/1/interests/2'
  end
  
  specify "resource_path(9) to /forums/1/interests/9" do
    controller.resource_path(9).should == '/forums/1/interests/9'
  end

  specify "edit_resource_path to /forums/1/interests/2;edit" do
    controller.edit_resource_path.should == '/forums/1/interests/2;edit'
  end
  
  specify "edit_resource_path(9) to /forums/1/interests/9;edit" do
    controller.edit_resource_path(9).should == '/forums/1/interests/9;edit'
  end
  
  specify "new_resource_path to /forums/1/interests/new" do
    controller.new_resource_path.should == '/forums/1/interests/new'
  end
end

context "resource_service in InterestsController via Forum" do
  controller_name :interests
  
  setup do
    @forum          = Forum.create
    @interest       = Interest.create :interested_in_id => @forum.id, :interested_in_type => 'Forum'
    @other_forum    = Forum.create
    @other_interest = Interest.create :interested_in_id => @other_forum.id, :interested_in_type => 'Forum'
    
    get :index, :forum_id => @forum.id
    @resource_service = controller.send :resource_service
  end
  
  specify "should build new interest with @forum fk and type with new" do
    resource = @resource_service.new
    resource.should_be_kind_of Interest
    resource.interested_in_id.should == @forum.id
    resource.interested_in_type.should == 'Forum'
  end
  
  specify "should find @interest with find(@interest.id)" do
    resource = @resource_service.find(@interest.id)
    resource.should_be == @interest
  end
  
  specify "should raise RecordNotFound with find(@other_interest.id)" do
    lambda{ @resource_service.find(@other_interest.id) }.should_raise ActiveRecord::RecordNotFound
  end

  specify "should find only interests belonging to @forum with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should_be == Interest.find(:all, :conditions => "interested_in_id = #{@forum.id} AND interested_in_type = 'Forum'")
  end
end

context "Requesting /forums/1/interests using GET" do
  include InterestsViaForumSpecHelper
  controller_name :interests

  setup do
    setup_mocks
    @interests = mock('Interests')
    @forum_interests.stub!(:find).and_return(@interests)
  end
  
  def do_get
    get :index, :forum_id => 1
  end

  specify "should find the forum" do
    Forum.should_receive(:find).with('1').and_return(@forum)
    do_get
  end

  specify "should assign the found forum as :interested_in for the view" do
    do_get
    assigns[:interested_in].should_be @forum
  end

  specify "should assign the forum_interests association as the interests resource_service" do
    @forum.should_receive(:interests).and_return(@forum_interests)
    do_get
    @controller.resource_service.should_be @forum_interests
  end 
end