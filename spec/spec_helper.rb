ENV["RAILS_ENV"] = "test"
require File.expand_path(File.join(File.dirname(__FILE__), "../../../../config/environment.rb"))
require 'spec/rails'

config = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'database.yml')))
ActiveRecord::Base.establish_connection(config['db'])

# Even if you're using RSpec, RSpec on Rails is reusing some of the
# Rails-specific extensions for fixtures and stubbed requests, response
# and other things (via RSpec's inherit mechanism). These extensions are 
# tightly coupled to Test::Unit in Rails, which is why you're seeing it here.
module Spec
  module Rails
    class EvalContext < Test::Unit::TestCase
      cattr_accessor :fixture_path, :use_transactional_fixtures, :use_instantiated_fixtures
      self.use_transactional_fixtures = true
      self.use_instantiated_fixtures  = false
      self.fixture_path = File.join(File.dirname(__FILE__), 'fixtures')

      # You can set up your global fixtures here, or you
      # can do it in individual contexts
      #fixtures :table_a, :table_b
    end
  end
end


# Testing app setup

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
  end
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end

class Forum < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
end

class UsersController < ActionController::Base
  resources_controller_for :users
end

class ForumsController < ActionController::Base
  resources_controller_for :forums
end

class PostsController < ActionController::Base
  resources_controller_for :posts
end

class UserPostsController < PostsController
  nested_in :user
end

class ForumPostsController < PostsController
  nested_in :forum
end

class CommentsController < ActionController::Base
  resources_controller_for :comments, :in => [:forum, :post]
end

ActionController::Routing::Routes.draw do |map|
  map.resources :users do |users|
    users.resources :posts, :name_prefix => 'user_', :controller => 'user_posts'
    users.resources :comments, :name_prefix => 'user_', :controller => 'user_comments'
  end
  map.resources :forums do |forums|
    forums.resources :posts, :name_prefix => 'forum_', :controller => 'forum_posts' do |posts|
      posts.resources :comments
    end
  end
end