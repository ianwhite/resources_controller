# Testing app setup

module ResourcesControllerTest
  class Application < Rails::Application
    config.secret_key_base = "1234567890-12345678912345678923456789"
    config.active_support.deprecation = :stderr
    config.eager_load = false
    config.action_controller.permit_all_parameters = true
    paths['config/database'] = File.expand_path('../app/database.yml', __FILE__)
    paths['log'] = File.expand_path('../../tmp/log', __FILE__)
  end
end

ResourcesControllerTest::Application.initialize!

##########
# Routing
##########

Rails.application
Rails.application.routes.clear!
Rails.application.routes.draw do
  # this tests :resource_path (or :erp), for named routes that map to resources
  root :controller => 'forums', :action => 'index', :resource_path => '/forums'
  get 'create_forum', :controller => 'forums', :action => 'create', :resource_path => '/forums', :resource_method => :post

  namespace :admin do
    resources :forums do
      resources :interests
    end
    namespace :superduper do
      resources :forums
    end
  end

  resources :users do
    resources :interests
    resources :posts, :controller => 'user_posts'
    resources :comments, :controller => 'user_comments'
    resources :addresses do
      resources :tags
    end
  end

  resources :forums do
    resources :interests
    resources :posts, :controller => 'forum_posts' do
      resources :comments do
        resources :tags
      end
      resources :tags
    end
    resource :owner do
      resources :posts do
        resources :tags
      end
    end
    resources :tags
  end

  resource :account do
    resources :posts
    resource :info do
      resources :tags
    end
  end

  resources :tags

  with_options :path_prefix => ":tag_id", :name_prefix => "tag_" do
    resources :forums
  end

  # the following routes are for testing errors
  resources :posts, :controller => 'forum_posts'
  resources :foos do
    resources :bars, :controller => 'forum_posts'
  end

  # DEPRECATED 
  # get ':controller/:action/:id(.:format)' # naming this so we can test missing segment errors
  
end


##################
# Database schema
##################

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :users, :force => true do |t|
      t.string :login
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

  def to_param
    login
  end
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
  has_many :users, :through => :posts
  belongs_to :owner, :class_name => "User"
end

class Post < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  has_many :comments
  has_many :tags, :as => :taggable
end

class Comment < ActiveRecord::Base
  validates_presence_of :user, :post

  belongs_to :user
  belongs_to :post
  has_many :tags, :as => :taggable
end

##############
# Controllers
##############

class ApplicationController < ActionController::Base
  map_enclosing_resource :account, :class => User, :singleton => true, :find => :current_user

  map_enclosing_resource :user do
    User.find_by_login(params[:user_id])
  end

protected
  def current_user
    @current_user
  end

  def resource_params
    params
  end
end

module Admin
  class ForumsController < ApplicationController
    resources_controller_for :forums

  end

  class InterestsController < ApplicationController
    resources_controller_for :interests
  end

  module NotANamespace
    class ForumsController < ApplicationController
      resources_controller_for :forums
    end
  end

  module Superduper
    class ForumsController < ApplicationController
      resources_controller_for :forums
    end
  end
end

class AccountsController < ApplicationController
  resources_controller_for :account, :singleton => true, :source => :user, :find => :current_user
  def account_params
    params.fetch(:account).permit()
  end
end

class InfosController < ApplicationController
  resources_controller_for :info, :singleton => true, :only => [:show, :edit, :update]
end

class TagsController < ApplicationController
  resources_controller_for :tags
end

class UsersController < ApplicationController
  resources_controller_for :users, :except => [:new, :create, :destroy]

protected
  def find_resource(id = params[:id])
    resource_service.find_by_login(id)
  end
  def user_params 
    params.fetch(:user, {}).permit(:login)
  end
end

class ForumsController < ApplicationController
  resources_controller_for :forums
  def forum_params 
    params.fetch(:forum, {}).permit(:title)
  end
end

class OwnersController < ApplicationController
  resources_controller_for :owner, :singleton => true, :class => User, :in => :forum
  def owner_params 
    params.fetch(:owner, {}).permit(:name)
  end
end

class PostsAbstractController < ApplicationController
  include ResourcesController::ResourceMethods
  attr_accessor :filter_trace

  # for testing filter load order
  before_action {|controller| controller.filter_trace ||= []; controller.filter_trace << :abstract}

protected
  # redefine find_resources
  def find_resources
    resource_service.order('id DESC')
  end
end

class PostsController < PostsAbstractController
  # for testing filter load order
  before_action {|controller| controller.filter_trace ||= []; controller.filter_trace << :posts}

  # example of providing options to resources_controller_for
  resources_controller_for :posts, :class => Post, :route => 'posts'

  # with trace
  def load_enclosing_resources(*args)
    self.filter_trace ||= []; self.filter_trace << :load_enclosing
    super(*args)
  end
  def post_params 
    params.fetch(:post, {}).permit(:body)
  end
end

class UserPostsController < PostsController
  # for testing filter load order
  before_action {|controller| controller.filter_trace ||= []; controller.filter_trace << :user_posts}

  # example of providing options to nested in
  nested_in :user, :class => User, :key => 'user_id', :name_prefix => 'user_'
end

class AddressesController < ApplicationController
  resources_controller_for :addresses
  def address_params 
    params.fetch(:address, {}).permit(:user_id, :name)
  end
end

class ForumPostsController < PostsController
  # for testing filter load order
  before_action {|controller| controller.filter_trace ||= []; controller.filter_trace << :forum_posts}

  # test override resources_controller_for use
  resources_controller_for :posts

  # example of providing a custom finder for the nesting resource
  # also example of :as option, which allows you to assign an alias
  # for an enclosing resource
  nested_in :forum, :as => :other_name_for_forum do
    Forum.find(params[:forum_id])
  end

  def post_params 
    params.fetch(:post, {}).permit(:user_id, :name)
  end
end

class CommentsController < ApplicationController
  resources_controller_for :comments, :in => [:forum, :post], :load_enclosing => false
  def comment_params 
    params.fetch(:comment, {}).permit(:user_id)
  end
end

class InterestsController < ApplicationController
  resources_controller_for :interests
  nested_in :interested_in, :polymorphic => true

  # the above two lines are the same as:
  #   resources_controller_for :interests, :in => '?interested_in'
end
