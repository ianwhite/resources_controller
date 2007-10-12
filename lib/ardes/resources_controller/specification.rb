module Ardes#:nodoc:
  module ResourcesController
    # This class holds all the info that is required to find a resource, or determine a name prefix, based on a route segment
    # or segment pair (e.g. /blog or /users/3).
    #
    # You don't need to instatiate this class directly - it is created by ResourcesController::ClassMethods#nested_in,
    # ResourcesController#map_resource (and ResourcesController::InstanceMethods#load_wildcards)
    #
    # This class is 'friendly' with controller, see load_into 
    class Specification
      attr_reader :name, :source, :klass, :key, :name_prefix, :segment, :find
      attr_accessor :controller
      delegate :enclosing_resource, :to => :controller

      # acts as a factory for Specification and SingletonSpecification
      #
      # you can call Specification.new 'name', :singleton => true
      def self.new(name, options = {}, &block)
        options.delete(:singleton) ? SingletonSpecification.new(name, options, &block) : super(name, options, &block)
      end
      
      # Example Usage
      #
      #  Specifcation.new <name>, <options hash>, <&block>
      #
      # _name_ should always be singular.
      #
      # Options:
      #
      # * <tt>:singleton:</tt> (default false) set this to true if the resource is a Singleton
      # * <tt>:find:</tt> (default null) set this to a symbol or Proc to specify how to find the resource.
      #   Use this if the resource is found in an unconventional way
      #
      # Options for unconvential use (otherwise these are all inferred from the _name_)
      # * <tt>:source:</tt> a plural string or symbol (e.g. :users).  This is used to find the class or association name
      # * <tt>:class:</tt> a Class.  This is the class of the resource (if it can't be inferred from _name_ or :source)
      # * <tt>:key:</tt> (e.g. :user_id) used to find the resource id in params
      # * <tt>:name_prefix:</tt> (e.g. 'user_') (set this to false if you want to specify that there is none)
      # * <tt>:segment:</tt> (e.g. 'users') the segment name in the route that is matched
      #
      # Passing a block is the same as passing :find => Proc
      def initialize(spec_name, options = {}, &block)
        options.assert_valid_keys(:class, :source, :key, :find, :name_prefix, :segment)
        @name        = spec_name.to_s
        @find        = block || options.delete(:find)
        @segment     = (options[:segment] && options[:segment].to_s) || name.pluralize
        @source      = (options[:source] && options[:source].to_s) || name.pluralize
        @name_prefix = options[:name_prefix] || (options[:name_prefix] == false ? '' : "#{name}_")
        @klass       = options[:class] || ((source && source.classify) || name.camelize).constantize
        @key         = (options[:key] && options[:key].to_s) || name.foreign_key
      end

      # returns false
      def singleton?
        false
      end
      
      # This method loads the resource into the passed controller, accessing some of the controller's
      # internals to do so.
      #
      # This is the 'friend' functionality
      def load_into(controller)
        self.controller = controller
        resource = find ? find_custom : find_resource
        controller.send(:update_name_prefix, name_prefix)
        controller.send(:enclosing_resources) << resource
        controller.send(:non_singleton_resources) << resource unless singleton?
        controller.send(:instance_variable_set, "@#{name}", resource)
      end

      # finds the resource using the custom :find Proc or symbol
      def find_custom
        raise "This specification has no custom :find attribute" unless find
        find.is_a?(Proc) ? controller.instance_eval(&find) : controller.send(find)
      end
      
      # finds the resource using enclosing resources or resource class
      def find_resource
        (enclosing_resource ? enclosing_resource.send(source) : klass).find controller.params[key]
      end
    end
  
    # A Singleton Specification
    class SingletonSpecification < Specification
      # Same as Specification except: 
      #
      # Options for unconvential use (otherwise these are all inferred from the _name_) 
      # * <tt>:source:</tt> a singular string or symbol (e.g. :blog).  This is used to find the class or association name
      # * <tt>:segment:</tt> (e.g. 'blog') the segment name in the route that is matched
      def initialize(spec_name, options = {}, &block)
        options[:segment] ||= spec_name.to_s
        options[:source]  ||= spec_name.to_s
        options[:class]   ||= (options[:source] || spec_name).to_s.camelize.constantize
        super(spec_name, options, &block)
      end

      # returns true
      def singleton?
        true
      end
    
      # finds the resource from the enclosing resource.  Raise CantFindSingleton if there is no enclosing resource
      def find_resource
        ResourcesController.raise_cant_find_singleton(name, klass) unless enclosing_resource
        enclosing_resource.send(source)
      end
    end
  end
end