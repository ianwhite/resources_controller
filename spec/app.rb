# Testing app setup

##################
# Database schema
##################

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :users, :force => true do |t|
    end

    create_table :addresses, :force => true do |t|
      t.column "user_id", :integer
    end
    
    create_table :forums, :force => true do |t|
    end

    create_table :posts, :force => true do |t|
      t.column "forum_id", :integer
      t.column "user_id", :integer
    end

    create_table :comments, :force => true do |t|
      t.column "post_id", :integer
      t.column "user_id", :integer
    end
    
    create_table :interests, :force => true do |t|
      t.column "interested_in_id", :integer
      t.column "interested_in_type", :string
    end
    
    create_table :tags, :force => true do |t|
      t.column "taggable_id", :integer
      t.column "taggable_type", :string
    end
  end
end


#########
# Models
#########

class Interest < ActiveRecord::Base
  belongs_to :interested_in, :polymorphic => true
end

class Tag < ActiveRecord::Base
  belongs_to :taggable, :polymorphic => true
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
  has_many :interests, :as => :interested_in
  has_many :addresses
end

class Address < ActiveRecord::Base
  belongs_to :user
  has_many :tags, :as => :taggable
end

class Forum < ActiveRecord::Base
  has_many :posts
  has_many :tags, :as => :taggable
  has_many :interests, :as => :interested_in
end

class Post < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  has_many :comments
  has_many :tags, :as => :taggable
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  has_many :tags, :as => :taggable
end


##############
# Controllers
##############

class UsersController < ActionController::Base
  resources_controller_for :users
end

class ForumsController < ActionController::Base
  resources_controller_for :forums
end

class PostsController < ActionController::Base
  # example of providing options to resources_controller_for
  resources_controller_for :posts, :class_name => 'Post', :route_name => 'posts', :name_prefix => ''
end

class UserPostsController < PostsController
  # example of providing options to nested in
  nested_in :user, :class_name => 'User', :foreign_key => 'user_id', :name_prefix => 'user_'
end

class AddressesController < ActionController::Base
  resources_controller_for :addresses, :in => :user
end

class ForumPostsController < PostsController
  # example of providing a custom finder for the nesting resource
  nested_in :forum do
    Forum.find(params[:forum_id])
  end
end

class CommentsController < ActionController::Base
  resources_controller_for :comments, :in => [:forum, :post]
end

class HasAComplexNameController < ActionController::Base
  resources_controller_for :users
end

class EnclosedByFooHasAComplexNameController < HasAComplexNameController
end

class InterestsController < ActionController::Base
  resources_controller_for :interests
  nested_in :interested_in, :polymorphic => true # could also use :anonymous => true
end

class TagsController < ActionController::Base
  resources_controller_for :tags
  nested_in :taggable, :polymorphic => true, :load_enclosing => true
end


##########
# Routing
##########

ActionController::Routing::Routes.draw do |map|
  map.resources :users do |users|
    users.resources :interests, :name_prefix => 'user_'
    users.resources :posts, :name_prefix => 'user_', :controller => 'user_posts'
    users.resources :comments, :name_prefix => 'user_', :controller => 'user_comments'
    users.resources :addresses do |addresses|
      addresses.resources :tags, :name_prefix => 'user_address_'
    end
  end
  map.resources :forums do |forums|
    forums.resources :interests, :name_prefix => 'forum_'
    forums.resources :tags, :name_prefix => 'forum_'
    forums.resources :posts, :name_prefix => 'forum_', :controller => 'forum_posts' do |posts|
      posts.resources :tags, :name_prefix => 'forum_post_'
      posts.resources :comments do |comments|
        comments.resources :tags, :name_prefix => 'forum_post_comment_'
      end
    end
  end
end