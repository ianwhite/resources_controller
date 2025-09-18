require 'spec_helper'

describe "(re: saved?) Comment" do
  describe ".new(<invalid attrs>)" do
    before { @comment = Comment.new }
    
    it { expect(@comment).not_to be_validation_attempted }
    it { expect(@comment).not_to be_saved }

    describe ".save" do
      before { @comment.save }

      it { expect(@comment).to be_validation_attempted }
      it { expect(@comment).not_to be_saved }

      describe "then update(<valid attrs>)" do
        before { @comment.update :user => User.create!, :post => Post.create! }
        
        it { expect(@comment).to be_validation_attempted }
        it { expect(@comment).to be_saved }
      end
    end
  end
end
