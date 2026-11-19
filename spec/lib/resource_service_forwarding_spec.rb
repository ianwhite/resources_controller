require 'spec_helper'

module ResourceServiceForwardingSpec
  class Service
    def probe(*args, **keywords, &block)
      [args, keywords, block]
    end

    def search(filters, limit:)
      [:search, filters, limit, yield(:search)]
    end

    def find(id, filters, limit:)
      [:find, id, filters, limit, yield(:find)]
    end

    def new(attributes, validate:)
      [:new, attributes, validate, yield(:new)]
    end

    def build(attributes, validate:)
      [:build, attributes, validate, yield(:build)]
    end

    def destroy(id, filters = nil, force: false)
      [:destroy, id, filters, force]
    end
  end

  Controller = Struct.new(:resource_class, :enclosing_resource, :resource_specification)
  Specification = Struct.new(:source, :find)

  class EnclosingResource < Struct.new(:items)
    def build_item(attributes, validate:)
      [:build_item, attributes, validate, yield(:build_item)]
    end
  end

  describe "Resource service argument forwarding" do
    let(:service) { Service.new }
    let(:enclosing_resource) { nil }
    let(:specification) { Specification.new(:items) }
    let(:controller) { Controller.new(service, enclosing_resource, specification) }
    let(:proxy_class) { ResourcesController::ResourceService }
    let(:proxy) { proxy_class.new(controller) }
    let(:attributes) { { :name => 'Example', :validate => true } }
    let(:filters) { { :limit => 1 } }

    it "preserves a trailing positional hash without adding keywords or a block" do
      expect(proxy.probe({ :limit => 1 })).to eq([[{ :limit => 1 }], {}, nil])
    end

    it "forwards positional hashes, keywords and blocks to dynamic service methods" do
      result = proxy.search(filters, limit: 2) { |operation| "block #{operation}" }

      expect(result).to eq([:search, filters, 2, 'block search'])
    end

    it "forwards positional hashes, keywords and blocks through find" do
      result = proxy.find(42, filters, limit: 2) { |operation| "block #{operation}" }

      expect(result).to eq([:find, 42, filters, 2, 'block find'])
    end

    it "calls service.find directly without falling back to method_missing" do
      expect(proxy).not_to receive(:method_missing)

      result = proxy.find(42, filters, limit: 2) { |operation| "block #{operation}" }
      expect(result).to eq([:find, 42, filters, 2, 'block find'])
    end

    it "invokes private #find on the underlying service and respects #controller overrides" do
      private_find_service = Class.new do
        private
        def find(id); [:private_find, id]; end
      end.new
      alt_controller = Controller.new(private_find_service, nil, specification)
      overriding_proxy = Class.new(ResourcesController::ResourceService) do
        define_method(:controller) { alt_controller }
      end.new(controller)

      expect(overriding_proxy.find(7)).to eq([:private_find, 7])
    end

    context "with a custom finder block" do
      let(:specification) do
        ResourcesController::Specification.new(:item, :class => Service) { [:custom, resource_class] }
      end

      it "runs the configured finder in the controller and ignores caller arguments and block" do
        result = proxy.find(42, filters, limit: 2) { raise 'caller block should not run' }

        expect(result).to eq([:custom, service])
      end
    end

    context "with a custom finder method" do
      let(:specification) do
        ResourcesController::Specification.new(:item, :class => Service, :find => :resource_class)
      end

      it "returns the controller method's result and ignores caller arguments and block" do
        result = proxy.find(42, filters, limit: 2) { raise 'caller block should not run' }

        expect(result).to equal(service)
      end
    end

    it "forwards positional hashes, keywords and blocks to top-level new" do
      result = proxy.new(attributes, validate: false) { |operation| "block #{operation}" }

      expect(result).to eq([:new, attributes, false, 'block new'])
    end

    context "with an enclosing resource" do
      let(:enclosing_resource) { EnclosingResource.new(service) }

      it "forwards positional hashes, keywords and blocks to the association's build" do
        result = proxy.new(attributes, validate: false) { |operation| "block #{operation}" }

        expect(result).to eq([:build, attributes, false, 'block build'])
      end

      it "forwards positional and keyword arguments through destroy to both find and service.destroy without forwarding blocks" do
        destroyed = nil
        find_block_given = nil
        destroy_block_given = nil
        allow(service).to receive(:find).with(42, filters, limit: 2) do |*_a, **_kw, &blk|
          find_block_given = !blk.nil?
          :found_record
        end
        allow(service).to receive(:destroy).with(42, filters, limit: 2) do |*a, **kw, &blk|
          destroy_block_given = !blk.nil?
          destroyed = [a, kw]
        end

        expect(proxy.destroy(42, filters, limit: 2) { raise 'block should not be forwarded' }).to eq(:found_record)
        expect(destroyed).to eq([[42, filters], {:limit => 2}])
        expect(find_block_given).to eq(false)
        expect(destroy_block_given).to eq(false)
      end

      it "respects subclass overrides of enclosing_resource and resource_specification" do
        custom_proxy_class = Class.new(ResourcesController::ResourceService) do
          def enclosing_resource
            nil
          end

          def resource_specification
            ResourcesController::Specification.new(:item, :class => Service) { :overridden_custom_find }
          end
        end

        custom_proxy = custom_proxy_class.new(controller)
        expect(custom_proxy.find(42)).to eq(:overridden_custom_find)
        expect(custom_proxy.new(attributes, validate: false) { |op| "block #{op}" }).to eq([:new, attributes, false, 'block new'])
      end
    end

    context "with a singleton resource service" do
      let(:proxy_class) { ResourcesController::SingletonResourceService }
      let(:specification) { Specification.new(:item) }

      it "forwards positional hashes, keywords and blocks to top-level new" do
        result = proxy.new(attributes, validate: false) { |operation| "block #{operation}" }

        expect(result).to eq([:new, attributes, false, 'block new'])
      end

      context "with an enclosing resource" do
        let(:enclosing_resource) { EnclosingResource.new(service) }

        it "forwards positional hashes, keywords and blocks to the singleton builder" do
          result = proxy.new(attributes, validate: false) { |operation| "block #{operation}" }

          expect(result).to eq([:build_item, attributes, false, 'block build_item'])
        end

        it "respects subclass overrides of enclosing_resource and resource_specification" do
          custom_singleton_class = Class.new(ResourcesController::SingletonResourceService) do
            def enclosing_resource
              nil
            end

            def resource_specification
              ResourcesController::Specification.new(:item, :singleton => true, :class => Service) { :overridden_singleton_find }
            end
          end

          custom_proxy = custom_singleton_class.new(controller)
          expect(custom_proxy.find).to eq(:overridden_singleton_find)
          expect(custom_proxy.new(attributes, validate: false) { |op| "block #{op}" }).to eq([:new, attributes, false, 'block new'])
        end
      end
    end
  end
end
