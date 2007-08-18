# Testing app setup
#
# TODO: modulize the testing app classes for minimal inteference with other plugin specs and app
#
# TODO: write more example specs which are to tied to concrete models, for usage purposes

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

class PostsAbstractController < ActionController::Base
  attr_accessor :filter_trace
  
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :abstract}
  
  # redefine find_resources
  def find_resources
    resource_service.find :all, :order => 'id DESC'
  end
end

class PostsController < PostsAbstractController
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :posts}
  
  # example of providing options to resources_controller_for
  resources_controller_for :posts, :class_name => 'Post', :route_name => 'posts', :name_prefix => ''
  
  def load_enclosing_with_trace(*args)
    self.filter_trace ||= []; self.filter_trace << :load_enclosing
    load_enclosing_without_trace(*args)
  end
  alias_method_chain :load_enclosing, :trace
end

class UserPostsController < PostsController
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :user_posts}
  
  # example of providing options to nested in
  nested_in :user, :class_name => 'User', :foreign_key => 'user_id', :name_prefix => 'user_'
end

class AddressesController < ActionController::Base
  resources_controller_for :addresses, :in => :user
end

class ForumPostsController < PostsController
  before_filter {|controller| controller.filter_trace ||= []; controller.filter_trace << :forum_posts}

  # example of providing a custom finder for the nesting resource
  nested_in :forum do
    Forum.find(params[:forum_id])
  end
end

class CommentsController < ActionController::Base
  resources_controller_for :comments, :in => [:forum, :post], :name_prefix => 'forum_post_'
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
  
  # here's an example of why it's best to stick to conventions.  The named routes for address
  # don't fit with the enclosing resources - so detect this when we've got an address
  before_filter do |controller|
    controller.name_prefix = 'address_' if controller.enclosing_resource.is_a?(Address)
    true
  end
end


##########
# Routing
##########

ActionController::Routing::Routes.draw do |map|
  map.resource :my_home do |my_home|
    my_home.resources :posts
    my_home.resource :info do |info|
      info.resources :tags
    end
  end
  
  map.resources :users do |users|
    users.resources :interests
    users.resources :posts, :controller => 'user_posts'
    users.resources :comments, :controller => 'user_comments'
    users.resources :addresses, :name_prefix => nil do |address|
      address.resources :tags
    end
  end
  map.resources :forums do |forums|
    forums.resource :owner do |owner|
      owner.resources :posts
    end
    forums.resources :interests
    forums.resources :tags
    forums.resources :posts, :controller => 'forum_posts' do |posts|
      posts.resources :tags
      posts.resources :comments do |comments|
        comments.resources :tags
      end
    end
  end
  
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end