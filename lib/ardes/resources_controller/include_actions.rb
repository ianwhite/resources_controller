module Ardes
  module ResourcesController
    # extension for any module that is used as an Actions module.
    #
    # After extending the module (say 'MyActions'), instead of doing this:
    #   self.include ActionsModule
    # do this:
    #   ActionsModule.include_actions(self, <:only or :except options>)
    #
    # RC extends any actions module with this automatically, so you don't need to know about it.
    #
    # However, if you ahve any special behaviour in your actions module that is sensitive to
    # :only and :except, you can define your own include_actions method on that module
    # to effect this special behaviour.
    module IncludeActions
      def include_actions(controller, options = {})
        options.assert_valid_keys(:only, :except)
        raise ArgumentError, "you can only specify either :except or :only, not both" if options[:only] && options[:except]
        
        mixin = self.dup
        if only = options[:only]
          only = Array(options[:only]).collect(&:to_s)
          mixin.instance_methods.each {|m| mixin.send(:undef_method, m) unless only.include?(m)}
        elsif except = options[:except]
          except = Array(options[:except]).collect(&:to_s)
          mixin.instance_methods.each {|m| mixin.send(:undef_method, m) if except.include?(m)}
        end
        controller.send :include, mixin
      end
    end
  end
end