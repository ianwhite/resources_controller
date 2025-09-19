require 'spec_helper'

describe CommentsController, "without stubs" do

  render_views

  before do
    @user = User.create!
    @forum = Forum.create!
    @post = Post.create! :forum => @forum
    @comment = Comment.create! :user => @user, :post => @post
  end
  
  describe "responding to GET index" do
    def do_get
      get :index, params: { :forum_id => @forum.id, :post_id => @post.id }
    end
    
    it "should expose all comments as @comments" do
      do_get
      expect(assigns[:comments]).to eq([@comment])
    end

    describe "with mime type of json" do
      it "should render all comments as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        do_get
        expect(response.body).to eq([@comment].to_json)
      end
    end
  end

  describe "responding to GET show" do
    def do_get
      get :show, params: { :id => @comment.id, :forum_id => @forum.id, :post_id => @post.id }
    end
    
    it "should expose the requested comment as @comment" do
      do_get
      expect(assigns[:comment]).to eq(@comment)
    end
    
    describe "with mime type of json" do
      it "should render the requested comment as json" do
        request.env["HTTP_ACCEPT"] = "application/json"
        do_get
        expect(response.body).to eq(@comment.to_json)
      end
    end
  end

  describe "responding to GET new" do
    def do_get
      get :new, params: { :forum_id => @forum.id, :post_id => @post.id }
    end
  
    it "should expose a new comment as @comment" do
      do_get
      expect(assigns[:comment]).to be_new_record
      expect(assigns[:comment].post).to eq(@post)
    end
  end

  describe "responding to GET edit" do
    def do_get
      get :edit, params: { :id => @comment.id, :forum_id => @forum.id, :post_id => @post.id }
    end
    
    it "should expose the requested comment as @comment" do
      do_get
      expect(assigns[:comment]).to eq(@comment)
    end
  end

  describe "responding to POST create" do
    describe "with valid params" do
      def do_post
        post :create, params: { :forum_id => @forum.id, :post_id => @post.id, :comment => {:user_id => @user.id} }
      end
      
      it "should create a comment" do
        expect { do_post }.to change(Comment, :count).by(1)
      end
      
      it "should expose the newly created comment as @comment" do
        do_post
        expect(assigns(:comment)).to eq(Comment.last)
      end

      it "should be resource_saved?" do
        do_post
        expect(@controller).to be_resource_saved
      end
      
      it "should redirect to the created comment" do
        do_post
        expect(response).to redirect_to(forum_post_comment_url(@forum, @post, Comment.last))
      end
    end
    
    describe "with invalid params" do
      def do_post
        post :create, params: { :forum_id => @forum.id, :post_id => @post.id, :comment => {:user_id => ''} }
      end

      it "should not create a comment" do
        expect { do_post }.not_to change(Comment, :count)
      end
 
      it "should expose a newly created but unsaved comment as @comment" do
        do_post
        expect(assigns(:comment)).to be_new_record
        expect(assigns(:comment).post).to eq(@post)
      end

      it "should not be resource_saved?" do
        do_post
        expect(@controller).not_to be_resource_saved
      end

      it "should re-render the 'new' template" do
        do_post
        expect(response).to render_template('new')
      end
    end
  end

  describe "responding to PUT update" do
    describe "with valid params" do
      before do
        @new_user = User.create!
      end
      
      def do_put
        put :update, params: { :id => @comment.id, :forum_id => @forum.id, :post_id => @post.id, :comment => {:user_id => @new_user.id} }
      end

      it "should update the requested comment" do
        do_put
        expect(Comment.find(@comment.id).user_id).to eq(@new_user.id)
      end

      it "should not contain errors on comment" do
        do_put
        expect(@comment.errors).to be_empty
      end
      
      it "should be resource_saved?" do
        do_put
        expect(@controller).to be_resource_saved
      end
      
      it "should expose the requested comment as @comment" do
        do_put
        expect(assigns[:comment]).to eq(@comment)
      end

      it "should redirect to the comment" do
        do_put
        expect(response).to redirect_to(forum_post_comment_url(@forum, @post, @comment))
      end
    end
    
    describe "with invalid params" do
      def do_put
        put :update, params: { :id => @comment.id, :forum_id => @forum.id, :post_id => @post.id, :comment => {:user_id => ''} }
      end

      it "should fail to update the requested comment" do
        do_put
        expect(Comment.find(@comment.id).user_id).to eq(@user.id) 
      end

      it "should not be resource_saved?" do
        do_put
        expect(@controller).not_to be_resource_saved
      end
      
      it "should expose the requested comment as @comment" do
        do_put
        expect(assigns[:comment]).to eq(@comment)
      end

      it "should re-render the 'edit' template" do
        do_put
        expect(response).to render_template('edit')
      end
    end
  end

  describe "responding to DELETE destroy" do
    def do_delete
      delete :destroy, params: { :id => @comment.id, :forum_id => @forum.id, :post_id => @post.id }
    end
    
    it "should delete the requested comment" do
      expect { do_delete }.to change(Comment, :count).by(-1)
    end

    it "should redirect to the comments list" do
      do_delete
      expect(response).to redirect_to(forum_post_comments_url(@forum, @post))
    end
  end
end
