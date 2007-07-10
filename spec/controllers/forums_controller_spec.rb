require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../app'))

describe "Routing shortcuts for Forums should map" do
  controller_name :forums
  
  before(:each) do
    @forum = mock('Forum')
    @forum.stub!(:to_param).and_return('2')
    Forum.stub!(:find).and_return(@forum)
    get :show, :id => "2"
  end
  
  it "resources_path to /forums" do
    controller.resources_path.should == '/forums'
  end

  it "resources_path(:foo => 'bar') to /forums?foo=bar" do
    controller.resources_path(:foo => 'bar').should == '/forums?foo=bar'
  end

  it "resource_path to /forums/2" do
    controller.resource_path.should == '/forums/2'
  end

  it "resource_path(:foo => 'bar') to /forums/2?foo=bar" do
    controller.resource_path(:foo => 'bar').should == '/forums/2?foo=bar'
  end
  
  it "resource_path(9) to /forums/9" do
    controller.resource_path(9).should == '/forums/9'
  end

  it "resource_path(9, :foo => 'bar') to /forums/2?foo=bar" do
    controller.resource_path(9, :foo => 'bar').should == '/forums/9?foo=bar'
  end

  it "edit_resource_path to /forums/2/edit" do
    controller.edit_resource_path.should == '/forums/2/edit'
  end
  
  it "edit_resource_path(9) to /forums/9/edit" do
    controller.edit_resource_path(9).should == '/forums/9/edit'
  end
  
  it "new_resource_path to /forums/new" do
    controller.new_resource_path.should == '/forums/new'
  end
  
  it "resources_url to http://test.host/forums" do
    controller.resources_url.should == 'http://test.host/forums'
  end

  it "resource_url to http://test.host/forums/2" do
    controller.resource_url.should == 'http://test.host/forums/2'
  end
  
  it "resource_url(9) to http://test.host/forums/9" do
    controller.resource_url(9).should == 'http://test.host/forums/9'
  end

  it "edit_resource_url to http://test.host/forums/2/edit" do
    controller.edit_resource_url.should == 'http://test.host/forums/2/edit'
  end
  
  it "edit_resource_url(9) to http://test.host/forums/9/edit" do
    controller.edit_resource_url(9).should == 'http://test.host/forums/9/edit'
  end
  
  it "new_resource_url to http://test.host/forums/new" do
    controller.new_resource_url.should == 'http://test.host/forums/new'
  end
 
  it "resource_interests_path to /forums/2/interests" do
    controller.resource_interests_path.should == "/forums/2/interests"
  end
  
  it "resource_interests_path(:foo => 'bar') to /forums/2/interests?foo=bar" do
    controller.resource_interests_path(:foo => 'bar').should == '/forums/2/interests?foo=bar'
  end
  
  it "resource_interests_path(9) to /forums/9/interests" do
    controller.resource_interests_path(9).should == "/forums/9/interests"
  end
  
  it "resource_interests_path(9, :foo => 'bar') to /forums/9/interests?foo=bar" do
    controller.resource_interests_path(9, :foo => 'bar').should == "/forums/9/interests?foo=bar"
  end

  it "resource_interest_path(5) to /forums/2/interests/5" do
    controller.resource_interest_path(5).should == "/forums/2/interests/5"
  end
  
  it "resource_interest_path(9,5) to /forums/9/interests/5" do
    controller.resource_interest_path(9,5).should == "/forums/9/interests/5"
  end
  
  it "resource_interest_path(9,5, :foo => 'bar') to /forums/9/interests/5?foo=bar" do
    controller.resource_interest_path(9, 5, :foo => 'bar').should == "/forums/9/interests/5?foo=bar"
  end

  it 'new_resource_interest_path(9) to /forums/9/interests/new' do
    controller.new_resource_interest_path(9).should == "/forums/9/interests/new"
  end
  
  it 'edit_resource_interest_path(5) to /forums/2/interests/5/edit' do
    controller.edit_resource_interest_path(5).should == "/forums/2/interests/5/edit"
  end
  
  it 'edit_resource_interest_path(9,5) to /forums/9/interests/5/edit' do
    controller.edit_resource_interest_path(9,5).should == "/forums/9/interests/5/edit"
  end
  
  it "resource_users_path should raise NoMethodError" do
    lambda{ controller.resource_users_path }.should raise_error(NoMethodError)
  end
end

describe "resource_service in ForumsController" do
  controller_name :forums
  
  before(:each) do
    @forum = Forum.create
    
    get :index
    @resource_service = controller.send :resource_service
  end
  
  it "should build new forum with new" do
    resource = @resource_service.new
    resource.should be_kind_of(Forum)
  end
  
  it "should find @forum with find(@forum.id)" do
    resource = @resource_service.find(@forum.id)
    resource.should == @forum
  end

  it "should find all forums with find(:all)" do
    resources = @resource_service.find(:all)
    resources.should == Forum.find(:all)
  end
end

describe "Requesting /forums using GET" do
  controller_name :forums

  before(:each) do
    @mock_forums = mock('forums')
    Forum.stub!(:find).and_return(@mock_forums)
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should render index.rhtml" do
    do_get
    response.should render_template(:index)
  end
  
  it "should find all forums" do
    Forum.should_receive(:find).with(:all).and_return(@mock_forums)
    do_get
  end
  
  it "should assign the found forums for the view" do
    do_get
    assigns[:forums].should == @mock_forums
  end
end

describe "Requesting /forums.xml using GET" do
  controller_name :forums

  before(:each) do
    @mock_forums = mock('forums')
    @mock_forums.stub!(:to_xml).and_return("XML")
    Forum.stub!(:find).and_return(@mock_forums)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find all forums" do
    Forum.should_receive(:find).with(:all).and_return(@mock_forums)
    do_get
  end
  
  it "should render the found forums as xml" do
    @mock_forums.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should eql("XML")
  end
end

describe "Requesting /forums/1 using GET" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum')
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    get :show, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render show.rhtml" do
    do_get
    response.should render_template(:show)
  end
  
  it "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_get
  end
  
  it "should assign the found forum for the view" do
    do_get
    assigns[:forum].should == @mock_forum
  end
end

describe "Requesting /forums/1.xml using GET" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum')
    @mock_forum.stub!(:to_xml).and_return("XML")
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_get
  end
  
  it "should render the found forum as xml" do
    @mock_forum.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should eql("XML")
  end
end

describe "Requesting /forums/new using GET" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum')
    Forum.stub!(:new).and_return(@mock_forum)
  end
  
  def do_get
    get :new
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render new.rhtml" do
    do_get
    response.should render_template(:new)
  end
  
  it "should create an new forum" do
    Forum.should_receive(:new).and_return(@mock_forum)
    do_get
  end
  
  it "should not save the new forum" do
    @mock_forum.should_not_receive(:save)
    do_get
  end
  
  it "should assign the new forum for the view" do
    do_get
    assigns[:forum].should == @mock_forum
  end
end

describe "Requesting /forums/1/edit using GET" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum')
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    get :edit, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render edit.rhtml" do
    do_get
    response.should render_template(:edit)
  end
  
  it "should find the forum requested" do
    Forum.should_receive(:find).and_return(@mock_forum)
    do_get
  end
  
  it "should assign the found Forum for the view" do
    do_get
    assigns(:forum).should equal(@mock_forum)
  end
end

describe "Requesting /forums using POST" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum')
    @mock_forum.stub!(:save).and_return(true)
    @mock_forum.stub!(:to_param).and_return("1")
    Forum.stub!(:new).and_return(@mock_forum)
  end
  
  def do_post
    post :create, :forum => {:name => 'Forum'}
  end
  
  it "should create a new forum" do
    Forum.should_receive(:new).with({'name' => 'Forum'}).and_return(@mock_forum)
    do_post
  end

  it "should redirect to the new forum" do
    do_post
    response.should be_redirect
    response.redirect_url.should == "http://test.host/forums/1"
  end
end

describe "Requesting /forums/1 using PUT" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum', :null_object => true)
    @mock_forum.stub!(:to_param).and_return("1")
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_update
    put :update, :id => "1"
  end
  
  it "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_update
  end

  it "should update the found forum" do
    @mock_forum.should_receive(:update_attributes)
    do_update
    assigns(:forum).should == @mock_forum
  end

  it "should assign the found forum for the view" do
    do_update
    assigns(:forum).should == @mock_forum
  end

  it "should redirect to the forum" do
    do_update
    response.should be_redirect
    response.redirect_url.should == "http://test.host/forums/1"
  end
end

describe "Requesting /forums/1 using DELETE" do
  controller_name :forums

  before(:each) do
    @mock_forum = mock('Forum', :null_object => true)
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_delete
    delete :destroy, :id => "1"
  end

  it "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_delete
  end
  
  it "should call destroy on the found forum" do
    @mock_forum.should_receive(:destroy)
    do_delete
  end
  
  it "should redirect to the forums list" do
    do_delete
    response.should be_redirect
    response.redirect_url.should == "http://test.host/forums"
  end
end