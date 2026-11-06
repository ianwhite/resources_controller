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
      end
    end
  end
end
