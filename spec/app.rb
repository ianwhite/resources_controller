# Testing app setup

##########
# Routing
##########

ActionController::Routing::Routes.draw do |map|
  map.resource :account do |account|
    account.resources :posts
    account.resource :info do |info|
      info.resources :tags
    end
  end
  
  map.resources :users do |user|
    user.resources :interests
    user.resources :posts, :controller => 'user_posts'
    user.resources :comments, :controller => 'user_comments'
    user.resources :addresses do |address|
      address.resources :tags
    end
  end
  map.resources :forums do |forum|
    forum.resource :owner do |owner|
      owner.resources :posts do |post|
        post.resources :tags
      end
    end
    forum.resources :interests
    forum.resources :tags
    forum.resources :posts, :controller => 'forum_posts' do |post|
      post.resources :tags
      post.resources :comments do |comment|
        comment.resources :tags
      end
    end
  end
  
  map.resources :tags
  
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end


##################
# Database schema
##################

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :users, :force => true do |t|
    end
    
    create_table :infos, :force => true do |t|
      t.column "user_id", :integer
    end

    create_table :addresses, :force => true do |t|
      t.column "user_id", :integer
    end
    
    create_table :forums, :force => true do |t|
      t.column "owner_id", :integer
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
  has_one :info
end

class Info < ActiveRecord::Base
  belongs_to :user
  has_many :tags, :as => :taggable
end

class Address < ActiveRecord::Base
  belongs_to :user
  has_many :tags, :as => :taggable
end

class Forum < ActiveRecord::Base
  has_many :posts
  has_many :tags, :as => :taggable
  has_many :interests, :as => :interested_in
  belongs_to :owner, :class_name => "User"
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

module AccountResource
  def self.extended(base)
    base.class_eval do
      # we add this so that controllers know how to find the singleton :account if it appears
      # in the enclosing resources
      map_enclosing_resource :account, :singleton => true do
        User.find(@current_user.id)
      end
    end
  end
end

class AccountController < ActionController::Base
  resources_controller_for :account, :class_name => 'User', :singleton => lambda { @current_user }  
end

class InfoController < ActionController::Base
  extend AccountResource
  resources_controller_for :info, :singleton => true, :load_enclosing => true
end

class TagsController < ActionController::Base
  extend AccountResource
  resources_controller_for :tags, :load_enclosing => true
end

class UsersController < ActionController::Base
  resources_controller_for :users
end

class ForumsController < ActionController::Base
  resources_controller_for :forums
end

class OwnerController < ActionController::Base
  resources_controller_for :owner, :class_name => 'User', :singleton => true, :in => :forum
end

class PostsAbstractController < ActionController::Base
  attr_accessor :filter_trace
  
  # for testing filter load order
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :abstract}
  
  # redefine find_resources
  def find_resources
    resource_service.find :all, :order => 'id DESC'
  end
end

class PostsController < PostsAbstractController
  # for testing filter load order
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :posts}
  
  # example of providing options to resources_controller_for
  resources_controller_for :posts, :class_name => 'Post', :route_name => 'posts'
  
  def load_resources_with_trace(*args)
    self.filter_trace ||= []; self.filter_trace << :load_enclosing
    load_resources_without_trace(*args)
  end
  alias_method_chain :load_resources, :trace
end

class UserPostsController < PostsController
  # for testing filter load order
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :user_posts}
  
  # example of providing options to nested in
  nested_in :user, :class_name => 'User', :foreign_key => 'user_id', :name_prefix => 'user_'
end

class AddressesController < ActionController::Base
  resources_controller_for :addresses, :in => :user
end

class ForumPostsController < PostsController
  # for testing filter load order
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :forum_posts}

  # example of providing a custom finder for the nesting resource
  nested_in :forum do
    Forum.find(params[:forum_id])
  end
end

class CommentsController < ActionController::Base
  resources_controller_for :comments, :in => [:forum, :post]
end

class InterestsController < ActionController::Base
  resources_controller_for :interests
  nested_in :interested_in, :polymorphic => true # could also use :anonymous => true
end