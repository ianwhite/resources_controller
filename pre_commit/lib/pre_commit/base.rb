module PreCommit
  class Base
    include Actor
    include Dependencies
    
    def initialize(actor, attrs = {})
      setup_actor(actor)
      attrs.each {|k,v| send("#{k}=", v)}
    end
    
    def pre_commit
      # your pre_commit code here
    end
    
  protected
    # decorate the actor with various support methods, and give
    # it a reference to this object
    def setup_actor(actor)
      class<<actor
        include Support
        attr_accessor :pre_commit
      end
      actor.pre_commit = self
      self.actor = actor
    end
  end
end