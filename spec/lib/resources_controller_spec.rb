require 'spec_helper'

describe "ResourcesController (in general)" do
  
  before do
    @controller = Class.new(ApplicationController)
    @controller.resources_controller_for :forums
  end
  
  it "nested_in :foo, :polymorphic => true, :class => User should raise argument error (no options or block with polymorphic)" do
    expect { @controller.nested_in :foo, :polymorphic => true, :class => User }.to raise_error(ArgumentError)
  end
  
  it "resources_controller_for :forums, :in => [:user, '*', '*', :comment] should raise argument error (no multiple wildcards in a row)" do
    expect { @controller.resources_controller_for :forums, :in => [:user, '*', '*', :comment] }.to raise_error(ArgumentError)
  end
end

describe "ResourcesController#enclosing_resource_name" do
  before do
    @controller = TagsController.new
    info = mock_model(Info, :tags => [])
    allow(@controller).to receive(:current_user).and_return(mock_model(User, :info => info))
    allow(@controller).to receive(:request_path).and_return('/account/info/tags')
    allow(@controller).to receive(:params).and_return({})
    @controller.send :load_enclosing_resources
  end

  it "should be the name of the mapped enclosing_resource" do
    expect(@controller.enclosing_resource_name).to eq('info')
  end
end

describe "A controller's resource_service" do
  before do
    @controller = ForumsController.new
  end
    
  it 'may be explicitly set with #resource_service=' do
    @controller.resource_service = 'foo'
    expect(@controller.resource_service).to eq('foo')
  end
end

describe "ResourcesController#update_name_prefix" do
  before do
    @controller = ForumsController.new
  end

  it "should accumulate the prefixes of the enclosing resources" do
    @controller.send :update_name_prefix, 'forum_'
    @controller.send :update_name_prefix, 'user_'
    expect(@controller.name_prefix).to eq('forum_user_')
  end

  it "should leave name_prefix as an empty String when the given prefix is empty or nil" do
    @controller.send :update_name_prefix, nil
    @controller.send :update_name_prefix, ''
    expect(@controller.instance_variable_get(:@name_prefix)).to eq('')
    expect(@controller.name_prefix).to eq('')
  end
end

describe "deprecated methods" do
  before do 
    @controller = ForumsController.new
    @controller.resource = Forum.new
  end
  
  it "#save_resource should send resource.save" do
    stub_const('ActiveSupport::Deprecation', Class.new do
      def self.warn(*args); end
    end)
    expect(@controller.resource).to receive :save
    @controller.save_resource
  end
end
