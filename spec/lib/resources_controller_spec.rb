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
    allow(@controller).to receive(:rc_request_path).and_return('/account/info/tags')
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
    @resource_service = @controller.resource_service
  end
    
  it 'may be explicitly set with #resource_service=' do
    @controller.resource_service = 'foo'
    expect(@controller.resource_service).to eq('foo')
  end

  # ResourceService is a BasicObject, so it has no #respond_to? to fall back on for
  # its own methods (see ResourceService::PROXY_METHODS)
  it 'should respond to its own methods' do
    expect(@resource_service.respond_to?(:controller)).to eq(true)
    expect(@resource_service.respond_to?(:service)).to eq(true)
    expect(@resource_service.respond_to?(:find)).to eq(true)
    expect(@resource_service.respond_to?(:new)).to eq(true)
    expect(@resource_service.respond_to?(:destroy)).to eq(true)
  end

  it 'should respond to the methods it delegates to the controller' do
    expect(@resource_service.respond_to?(:resource_specification)).to eq(true)
    expect(@resource_service.respond_to?(:resource_class)).to eq(true)
    expect(@resource_service.respond_to?(:enclosing_resource)).to eq(true)
  end

  it 'should respond to the methods of the service it proxies' do
    expect(Forum.respond_to?(:count)).to eq(true)
    expect(@resource_service.respond_to?(:count)).to eq(true)
    expect(@resource_service.respond_to?(:no_such_method_at_all)).to eq(false)
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

describe "ResourcesController::Specification" do
  it "should keep singleton key false and compute collection_ivar_name lazily" do
    spec = ResourcesController::Specification.new(:account, :singleton => true, :class => User)
    expect(spec.key).to eq(false)
    expect(spec.instance_variable_get(:@collection_ivar_name)).to be_nil
    expect(spec.collection_ivar_name).to eq(:@accounts)
  end

  it "should treat false for :segment, :source, and :key as absent" do
    spec = ResourcesController::Specification.new(:forum, :segment => false, :source => false, :key => false)
    expect(spec.segment).to eq('forums')
    expect(spec.source).to eq('forums')
    expect(spec.klass).to eq(Forum)
    expect(spec.key).to eq('forum_id')
  end
end

describe "ResourcesController#add_enclosing_resource hook" do
  it "should invoke add_enclosing_resource overrides during load_enclosing_resources" do
    forum = Forum.create!
    klass = Class.new(ApplicationController) do
      resources_controller_for :posts, :in => :forum
      attr_reader :added_enclosing

      private

      def add_enclosing_resource(resource, options = {})
        (@added_enclosing ||= []) << [resource, options[:name]]
        super
      end
    end

    controller = klass.new
    req = ActionDispatch::TestRequest.create
    req.path = "/forums/#{forum.id}/posts"
    allow(controller).to receive(:request).and_return(req)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(:forum_id => forum.id.to_s))

    controller.send(:load_enclosing_resources)
    expect(controller.added_enclosing).to eq([[forum, 'forum']])
    expect(controller.instance_variable_get(:@forum)).to eq(forum)
  end

  it "should support :as on a mapped wildcard specification" do
    account = User.create!
    klass = Class.new(ApplicationController) do
      resources_controller_for :tags, :in => '?taggable'
    end

    controller = klass.new
    controller.instance_variable_set(:@current_user, account)
    req = ActionDispatch::TestRequest.create
    req.path = '/account/tags'
    allow(controller).to receive(:request).and_return(req)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new)

    controller.send(:load_enclosing_resources)
    expect(controller.instance_variable_get(:@account)).to eq(account)
    expect(controller.instance_variable_get(:@taggable)).to eq(account)
  end

  it "should raise ResourceMismatch when nesting segments are exhausted for a specification" do
    klass = Class.new(ApplicationController) do
      resources_controller_for :posts, :in => :forum
    end

    controller = klass.new
    req = ActionDispatch::TestRequest.create
    req.path = '/posts'
    allow(controller).to receive(:request).and_return(req)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new)

    expect { controller.send(:load_enclosing_resources) }.to raise_error(ResourcesController::ResourceMismatch)
  end

  it "should raise ResourceMismatch when wildcard lookup exhausts nesting segments" do
    user = User.create!
    klass = Class.new(ApplicationController) do
      resources_controller_for :tags, :in => [:user, '?taggable', :forum]
    end

    controller = klass.new
    req = ActionDispatch::TestRequest.create
    req.path = "/users/#{user.id}/tags"
    allow(controller).to receive(:request).and_return(req)
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(:user_id => user.id.to_s))

    expect { controller.send(:load_enclosing_resources) }.to raise_error(ResourcesController::ResourceMismatch)
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
