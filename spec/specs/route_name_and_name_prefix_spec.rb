require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

context "ResourcesController (route_name, singular_route_name and name_prefix)" do
  specify "route_name should be the controller_name by default" do
    PostsController.route_name.should == PostsController.controller_name
  end
  
  specify "singular_route_name should be route_name.singualrize(d)" do
    PostsController.singular_route_name.should == PostsController.route_name.singularize
  end
  
  specify "should inherit route_name and singular_route_name from parent, unless explicitly set" do
    ForumPostsController.route_name.should == PostsController.route_name
    ForumPostsController.singular_route_name.should == PostsController.singular_route_name
    
    ForumPostsController.route_name = 'foos'
    
    ForumPostsController.route_name.should == 'foos'
    ForumPostsController.singular_route_name.should == 'foo'
    
    ForumPostsController.route_name = PostsController.route_name
  end
  
  specify "should allow overriding on instance, and not affect class route_name, singular_route_name, or name_prefix" do
    f = ForumPostsController.new
    f.route_name = 'foos'
    f.name_prefix = 'bar_'
    
    f.route_name.should == 'foos'
    f.singular_route_name.should == 'foo'
    f.name_prefix.should == 'bar_'
    
    ForumPostsController.route_name.should == 'posts'
    ForumPostsController.singular_route_name.should == 'post'
    ForumPostsController.name_prefix.should == 'forum_'
  end
end

context "Automatic (route_name, name_prefix) for" do
  
  def route_name_and_name_prefix_for(controller)
    [controller.route_name, controller.name_prefix]
  end
  
  specify "ForumsController should be ('forums', '')" do
    route_name_and_name_prefix_for(ForumsController).should == ['forums', '']
  end
  
  specify "PostsController should be ('posts', '')" do
    route_name_and_name_prefix_for(PostsController).should == ['posts', '']
  end
  
  specify "ForumPostsController should be ('posts', 'forum_')" do
    route_name_and_name_prefix_for(ForumPostsController).should == ['posts', 'forum_']
  end
  
  specify "UserPostsController should be ('posts', 'user_')" do
    route_name_and_name_prefix_for(UserPostsController).should == ['posts', 'user_']
  end

  specify "CommentsController should be ('comments', '')" do
    route_name_and_name_prefix_for(CommentsController).should == ['comments', '']
  end
  
  #specify "TagsController should be ('tags', '')" do
  #  route_name_and_name_prefix_for(TagsController).should == ['tags', '']
  #end
  
  #specify "ForumTagsController should be ('tags', 'forum_')" do
  #  route_name_and_name_prefix_for(ForumTagsController).should == ['tags', 'forum_']
  #end

  #specify "PostTagsController should be ('tags', 'post_')" do
  #  route_name_and_name_prefix_for(PostTagsController).should == ['tags', 'post_']
  #end
  
  specify "HasAComplexNameController should be ('has_a_complex_name', '')" do
    route_name_and_name_prefix_for(HasAComplexNameController).should == ['has_a_complex_name', '']
  end

  specify "EnclosedByFooHasAComplexNameController should be ('has_a_complex_name', 'enclosed_by_foo_')" do
    route_name_and_name_prefix_for(EnclosedByFooHasAComplexNameController).should == ['has_a_complex_name', 'enclosed_by_foo_']
  end
end