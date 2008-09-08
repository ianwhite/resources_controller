module Ardes#:nodoc:
  module ActiveRecord#:nodoc:
    # Small mixin which lets you find the result of the last save on an active record
    #
    # Example usage:
    #
    #  foo = Foo.new
    #
    #  foo.attempted_save?  # => false
    #  foo.saved?           # => nil
    #
    #  foo.save             # => true
    #  foo.attempted_save?  # => true
    #  foo.saved?           # => true
    #  
    #  foo.update_attributes(:invalid => true) # => false
    #  foo.attempted_save?  # => true
    #  foo.saved?           # => false
    #
    #  foo.reload
    #  foo.attempted_save?  # => false
    #  foo.saved?           # => false
    module Saved
      def self.included(base)
        base.class_eval do
          def save_with_saved(*args)
            @_saved = save_without_saved(*args)
          end
          alias_method_chain :save, :saved
          
          def reload_with_saved(*args)
            @_saved = nil
            reload_without_saved(*args)
          end
          alias_method_chain :reload, :saved
          
          # returns:
          #  nil   - if the record has had no save attempt
          #  true  - if the record was saved successfuly
          #  false - if the record was saved unsuccesfuly
          def saved?
            @_saved
          end
          
          # returns:
          #  true  - if the record has had a save attempt
          #  false - if the record has not had a save attempt
          # (this is simply a predicate method for checking saved?.nil?)
          def attempted_save?
            !@_saved.nil?
          end
        end
      end
    end
  end
end
      