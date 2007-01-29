require File.dirname(__FILE__) + '/../spec_helper'

class Thing < ActiveRecord::Base
end

class ThingsController < ActionController::Base
  rest_controller_for :things
end

ActionController::Routing::Routes.draw do |map|
  map.resources :things
end

context "Routes for the ThingsController should map" do
  controller_name :things

  specify "{ :controller => 'things', :action => 'index' } to /things" do
    route_for(:controller => "things", :action => "index").should_eql "/things"
  end
  
  specify "{ :controller => 'things', :action => 'new' } to /things/new" do
    route_for(:controller => "things", :action => "new").should_eql "/things/new"
  end
  
  specify "{ :controller => 'things', :action => 'show', :id => 1 } to /things/1" do
    route_for(:controller => "things", :action => "show", :id => 1).should_eql "/things/1"
  end
  
  specify "{ :controller => 'things', :action => 'edit', :id => 1 } to /things/1;edit" do
    route_for(:controller => "things", :action => "edit", :id => 1).should_eql "/things/1;edit"
  end
  
  specify "{ :controller => 'things', :action => 'update', :id => 1} to /things/1" do
    route_for(:controller => "things", :action => "update", :id => 1).should_eql "/things/1"
  end
  
  specify "{ :controller => 'things', :action => 'destroy', :id => 1} to /things/1" do
    route_for(:controller => "things", :action => "destroy", :id => 1).should_eql "/things/1"
  end
end

context "Requesting /things using GET" do
  controller_name :things

  setup do
    @mock_things = mock('things')
    Thing.stub!(:find).and_return(@mock_things)
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
  
  specify "should find all things" do
    Thing.should_receive(:find).with(:all).and_return(@mock_things)
    do_get
  end
  
  specify "should assign the found things for the view" do
    do_get
    assigns[:things].should_be @mock_things
    
  end
end

context "Requesting /things.xml using GET" do
  controller_name :things

  setup do
    @mock_things = mock('things')
    @mock_things.stub!(:to_xml).and_return("XML")
    Thing.stub!(:find).and_return(@mock_things)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :index
  end
  
  specify "should be successful" do
    do_get
    response.should_be_success
  end

  specify "should find all things" do
    Thing.should_receive(:find).with(:all).and_return(@mock_things)
    do_get
  end
  
  specify "should render the found things as xml" do
    @mock_things.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should_eql "XML"
  end
end

context "Requesting /things/1 using GET" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing')
    Thing.stub!(:find).and_return(@mock_thing)
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
  
  specify "should find the thing requested" do
    Thing.should_receive(:find).with("1").and_return(@mock_thing)
    do_get
  end
  
  specify "should assign the found thing for the view" do
    do_get
    assigns[:thing].should_be @mock_thing
  end
end

context "Requesting /things/1.xml using GET" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing')
    @mock_thing.stub!(:to_xml).and_return("XML")
    Thing.stub!(:find).and_return(@mock_thing)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "1"
  end

  specify "should be successful" do
    do_get
    response.should_be_success
  end
  
  specify "should find the thing requested" do
    Thing.should_receive(:find).with("1").and_return(@mock_thing)
    do_get
  end
  
  specify "should render the found thing as xml" do
    @mock_thing.should_receive(:to_xml).and_return("XML")
    do_get
    response.body.should_eql "XML"
  end
end

context "Requesting /things/new using GET" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing')
    Thing.stub!(:new).and_return(@mock_thing)
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
  
  specify "should create an new thing" do
    Thing.should_receive(:new).and_return(@mock_thing)
    do_get
  end
  
  specify "should not save the new thing" do
    @mock_thing.should_not_receive(:save)
    do_get
  end
  
  specify "should assign the new thing for the view" do
    do_get
    assigns[:thing].should_be @mock_thing
  end
end

context "Requesting /things/1;edit using GET" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing')
    Thing.stub!(:find).and_return(@mock_thing)
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
  
  specify "should find the thing requested" do
    Thing.should_receive(:find).and_return(@mock_thing)
    do_get
  end
  
  specify "should assign the found Thing for the view" do
    do_get
    assigns(:thing).should_equal @mock_thing
  end
end

context "Requesting /things using POST" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing')
    @mock_thing.stub!(:save).and_return(true)
    @mock_thing.stub!(:to_param).and_return(1)
    Thing.stub!(:new).and_return(@mock_thing)
  end
  
  def do_post
    post :create, :thing => {:name => 'Thing'}
  end
  
  specify "should create a new thing" do
    Thing.should_receive(:new).with({'name' => 'Thing'}).and_return(@mock_thing)
    do_post
  end

  specify "should redirect to the new thing" do
    do_post
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/things/1"
  end
end

context "Requesting /things/1 using PUT" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing', :null_object => true)
    @mock_thing.stub!(:to_param).and_return(1)
    Thing.stub!(:find).and_return(@mock_thing)
  end
  
  def do_update
    put :update, :id => "1"
  end
  
  specify "should find the thing requested" do
    Thing.should_receive(:find).with("1").and_return(@mock_thing)
    do_update
  end

  specify "should update the found thing" do
    @mock_thing.should_receive(:update_attributes)
    do_update
    assigns(:thing).should_be @mock_thing
  end

  specify "should assign the found thing for the view" do
    do_update
    assigns(:thing).should_be @mock_thing
  end

  specify "should redirect to the thing" do
    do_update
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/things/1"
  end
end

context "Requesting /things/1 using DELETE" do
  controller_name :things

  setup do
    @mock_thing = mock('Thing', :null_object => true)
    Thing.stub!(:find).and_return(@mock_thing)
  end
  
  def do_delete
    delete :destroy, :id => "1"
  end

  specify "should find the thing requested" do
    Thing.should_receive(:find).with("1").and_return(@mock_thing)
    do_delete
  end
  
  specify "should call destroy on the found thing" do
    @mock_thing.should_receive(:destroy)
    do_delete
  end
  
  specify "should redirect to the things list" do
    do_delete
    response.should_be_redirect
    response.redirect_url.should_eql "http://test.host/things"
  end
end