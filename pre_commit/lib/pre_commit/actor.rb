module PreCommit
  module Actor
    def self.included(base)
      base.class_eval do
        attr_accessor :actor
      end
    end
    
    def respond_to?(meth)
      super || actor.respond_to?(meth)
    end
  
  protected
    def method_missing(meth, *args, &block)
      actor.respond_to?(meth) ? actor.send(meth, *args, &block) : super
    end
  end
end