# Testing app setup

##################
# Database schema
##################

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :users, :force => true do |t|
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

class ApplicationController < ActionController::Base
end

class UsersController < ApplicationController
  resources_controller_for :users
end

class ForumsController < ApplicationController
  resources_controller_for :forums
end

class PostsController < ApplicationController
  resources_controller_for :posts
end

class UserPostsController < PostsController
  nested_in :user
end

class ForumPostsController < PostsController
  nested_in :forum
end

class CommentsController < ApplicationController
  resources_controller_for :comments, :in => [:forum, :post]
end

class HasAComplexNameController < ApplicationController
  resources_controller_for :users
end

class EnclosedByFooHasAComplexNameController < HasAComplexNameController
end

class InterestsController < ApplicationController
  resources_controller_for :interests
  nested_in :interested_in, :polymorphic => true # could also use :anonymous => true
end

class TagsController < ApplicationController
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