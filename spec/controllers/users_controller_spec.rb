require 'spec_helper'

describe UsersController, "routing" do

  it "should route to { :controller => 'users', action => 'index' } from GET /users" do
    expect({:get => "/users"}).to route_to(:controller => "users", :action => "index")
  end
  
  it "should route to { :controller => 'users', action => 'new' } from GET /users/new" do
    expect({:get => "/users/new"}).to route_to(:controller => "users", :action => "new")
  end
  
  it "should route to { :controller => 'users', action => 'create' } from POST /users" do
    expect({:post => "/users"}).to route_to(:controller => "users", :action => "create")
  end
  
  it "should route to { :controller => 'users', action => 'show', id => '1' } from GET /users/dave" do
    expect({:get => "/users/dave"}).to route_to(:controller => "users", :action => "show", :id => "dave")
  end
  
  it "should route to { :controller => 'users', action => 'edit', id => '1' } from GET /users/dave/edit" do
    expect({:get => "/users/dave/edit"}).to route_to(:controller => "users", :action => "edit", :id => "dave")
  end
  
  it "should route to { :controller => 'users', action => 'update', id => '1' } from PUT /users/dave" do
    expect({:put => "/users/dave"}).to route_to(:controller => "users", :action => "update", :id => "dave")
  end
  
  it "should route to { :controller => 'users', action => 'destroy', id => '1' } from DELETE /users/dave" do
    expect({:delete => "/users/dave"}).to route_to(:controller => "users", :action => "destroy", :id => "dave")
  end
  
end

describe UsersController, "handling GET /users" do
  render_views

  before do
    @user = mock_model(User)
    allow(User).to receive(:all).and_return([@user])
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    expect(response).to be_success
  end

  it "should render index template" do
    do_get
    expect(response).to render_template('index')
  end
  
  it "should find all users" do
    expect(User).to receive(:all).and_return([@user])
    do_get
  end
  
  it "should assign the found users for the view" do
    do_get
    expect(assigns[:users]).to eq([@user])
  end
end

describe UsersController, "handling GET /users.json" do
  render_views

  before do
    @user = mock_model(User, :to_json => "JSON")
    allow(User).to receive(:all).and_return(@user)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/json"
    get :index
  end
  
  it "should be successful" do
    do_get
    expect(response).to be_success
  end

  it "should find all users" do
    expect(User).to receive(:all).and_return([@user])
    do_get
  end
  
  it "should render the found users as json" do
    expect(@user).to receive(:to_json).and_return("JSON")
    do_get
    expect(response.body).to eq("JSON")
  end
end

describe UsersController, "handling GET /users/dave" do

  before do
    @user = mock_model(User)
    allow(User).to receive(:find_by_login).and_return(@user)
  end
  
  def do_get
    get :show, params: { :id => "dave" }
  end

  it "should be successful" do
    do_get
    expect(response).to be_success
  end
  
  it "should render show template" do
    do_get
    expect(response).to render_template('show')
  end
  
  it "should find the user requested" do
    expect(User).to receive(:find_by_login).with("dave").and_return(@user)
    do_get
  end
  
  it "should assign the found user for the view" do
    do_get
    expect(assigns[:user]).to equal(@user)
  end
end

describe UsersController, "handling GET /users/dave.json" do
  render_views

  before do
    @user = mock_model(User, :to_json => "JSON")
    allow(User).to receive(:find_by_login).and_return(@user)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/json"
    get :show, params: { :id => "dave" }, :format => :json
  end

  it "should be successful" do
    do_get
    expect(response).to be_success
  end
  
  it "should find the user requested" do
    expect(User).to receive(:find_by_login).with("dave").and_return(@user)
    do_get
  end
  
  it "should render the found user as json" do
    expect(@user).to receive(:to_json).and_return("JSON")
    do_get
    expect(response.body).to eq("JSON")
  end
end

describe UsersController, "handling GET /users/new" do
  it "should be unknown action" do
    expect{ get :new }.to raise_error(::AbstractController::ActionNotFound)
  end
end

describe UsersController, "handling GET /users/dave/edit" do

  before do
    @user = mock_model(User)
    allow(User).to receive(:find_by_login).and_return(@user)
  end
  
  def do_get
    get :edit, params: { :id => "dave" }
  end

  it "should be successful" do
    do_get
    expect(response).to be_success
  end
  
  it "should render edit template" do
    do_get
    expect(response).to render_template('edit')
  end
  
  it "should find the user requested" do
    expect(User).to receive(:find_by_login).and_return(@user)
    do_get
  end
  
  it "should assign the found User for the view" do
    do_get
    expect(assigns[:user]).to equal(@user)
  end
end

describe UsersController, "handling POST /users" do
  it "should be unknown action" do
    expect{ post :create }.to raise_error(::AbstractController::ActionNotFound)
  end
end

describe UsersController, "handling PUT /users/dave" do

  before do
    @user = mock_model(User, :to_param => "dave")
    allow(User).to receive(:find_by_login).and_return(@user)
  end
  
  def put_with_successful_update
    expect(@user).to receive(:update).and_return(true)
    put :update, params: { :id => "dave" }
  end
  
  def put_with_failed_update
    expect(@user).to receive(:update).and_return(false)
    put :update, params: { :id => "dave" }
  end
  
  it "should find the user requested" do
    expect(User).to receive(:find_by_login).with("dave").and_return(@user)
    put_with_successful_update
  end

  it "should update the found user" do
    put_with_successful_update
    expect(assigns(:user)).to equal(@user)
  end

  it "should assign the found user for the view" do
    put_with_successful_update
    expect(assigns(:user)).to equal(@user)
  end

  it "should redirect to the user on successful update" do
    put_with_successful_update
    expect(response).to redirect_to(user_url("dave"))
  end

  it "should re-render 'edit' on failed update" do
    put_with_failed_update
    expect(response).to render_template('edit')
  end
end

describe UsersController, "handling DELETE /users/dave" do
  it "should be unknown action" do
    expect{ delete :destroy, params: { :id => "dave" } }.to raise_error(::AbstractController::ActionNotFound)
  end
end
