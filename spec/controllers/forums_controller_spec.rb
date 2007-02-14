require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

context "Routing shortcuts for ForumPosts (forums/1) should map" do
  controller_name :forums
  
  setup do
    @forum = mock('Forum')
    @forum.stub!(:to_param).and_return('2')
    Forum.stub!(:find).and_return(@forum)
    get :show, :id => "2"
  end
  
  specify "resources_path to /forums" do
    controller.resources_path.should == '/forums'
  end

  specify "resource_path to /forums/2" do
    controller.resource_path.should == '/forums/2'
  end
  
  specify "resource_path(9) to /forums/9" do
    controller.resource_path(9).should == '/forums/9'
  end

  specify "edit_resource_path to /forums/2;edit" do
    controller.edit_resource_path.should == '/forums/2;edit'
  end
  
  specify "edit_resource_path(9) to /forums/9;edit" do
    controller.edit_resource_path(9).should == '/forums/9;edit'
  end
  
  specify "new_resource_path to /forums/new" do
    controller.new_resource_path.should == '/forums/new'
  end
end

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

context "Requesting /forums using GET" do
  controller_name :forums

  setup do
    @mock_forums = mock('forums')
    Forum.stub!(:find).and_return(@mock_forums)
  end
  
  def do_get
    get :index
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should render index.rhtml" do
    controller.should_render :index
    do_get
  end
  
  specify "should find all forums" do
    Forum.should_receive(:find).with(:all).and_return(@mock_forums)
    do_get
  end
  
  specify "should assign the found forums for the view" do
    do_get
    assigns[:forums].should_be @mock_forums
  end
end

context "Requesting /forums.xml using GET" do
  controller_name :forums

  setup do
    @mock_forums = mock('forums')
    @mock_forums.stub!(:to_xml).and_return("XML")
    Forum.stub!(:find).and_return(@mock_forums)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :index
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should find all forums" do
    Forum.should_receive(:find).with(:all).and_return(@mock_forums)
    do_get
  end
  
  specify "should render the found forums as xml" do
    @mock_forums.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should_eql "XML"
  end
end

context "Requesting /forums/1 using GET" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum')
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    get :show, :id => "1"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render show.rhtml" do
    controller.should_render :show
    do_get
  end
  
  specify "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_get
  end
  
  specify "should assign the found forum for the view" do
    do_get
    assigns[:forum].should_be @mock_forum
  end
end

context "Requesting /forums/1.xml using GET" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum')
    @mock_forum.stub!(:to_xml).and_return("XML")
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "1"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_get
  end
  
  specify "should render the found forum as xml" do
    @mock_forum.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should_eql "XML"
  end
end

context "Requesting /forums/new using GET" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum')
    Forum.stub!(:new).and_return(@mock_forum)
  end
  
  def do_get
    get :new
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render new.rhtml" do
    controller.should_render :new
    do_get
  end
  
  specify "should create an new forum" do
    Forum.should_receive(:new).and_return(@mock_forum)
    do_get
  end
  
  specify "should not save the new forum" do
    @mock_forum.should_not_receive(:save)
    do_get
  end
  
  specify "should assign the new forum for the view" do
    do_get
    assigns[:forum].should_be @mock_forum
  end
end

context "Requesting /forums/1;edit using GET" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum')
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_get
    get :edit, :id => "1"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should render edit.rhtml" do
    do_get
    controller.should_render :edit
  end
  
  specify "should find the forum requested" do
    Forum.should_receive(:find).and_return(@mock_forum)
    do_get
  end
  
  specify "should assign the found Forum for the view" do
    do_get
    assigns(:forum).should_equal @mock_forum
  end
end

context "Requesting /forums using POST" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum')
    @mock_forum.stub!(:save).and_return(true)
    @mock_forum.stub!(:to_param).and_return("1")
    Forum.stub!(:new).and_return(@mock_forum)
  end
  
  def do_post
    post :create, :forum => {:name => 'Forum'}
  end
  
  specify "should create a new forum" do
    Forum.should_receive(:new).with({'name' => 'Forum'}).and_return(@mock_forum)
    do_post
  end

  specify "should redirect to the new forum" do
    do_post
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/1"
  end
end

context "Requesting /forums/1 using PUT" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum', :null_object => true)
    @mock_forum.stub!(:to_param).and_return("1")
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_update
    put :update, :id => "1"
  end
  
  specify "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_update
  end

  specify "should update the found forum" do
    @mock_forum.should_receive(:update_attributes)
    do_update
    assigns(:forum).should_be @mock_forum
  end

  specify "should assign the found forum for the view" do
    do_update
    assigns(:forum).should_be @mock_forum
  end

  specify "should redirect to the forum" do
    do_update
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums/1"
  end
end

context "Requesting /forums/1 using DELETE" do
  controller_name :forums

  setup do
    @mock_forum = mock('Forum', :null_object => true)
    Forum.stub!(:find).and_return(@mock_forum)
  end
  
  def do_delete
    delete :destroy, :id => "1"
  end

  specify "should find the forum requested" do
    Forum.should_receive(:find).with("1").and_return(@mock_forum)
    do_delete
  end
  
  specify "should call destroy on the found forum" do
    @mock_forum.should_receive(:destroy)
    do_delete
  end
  
  specify "should redirect to the forums list" do
    do_delete
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/forums"
  end
end