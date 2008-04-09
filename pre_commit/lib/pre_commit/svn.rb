module PreCommit
  module Svn
    def self.included(base)
      base.class_eval do
        cattr_accessor :do_not_clobber
        self.do_not_clobber = []
      end
    end
    
    # clobber all files except dependencies and those managed by subversion in path
    def clobber_using_svn(path = ".", to_keep = self.do_not_clobber)
      puts "Clobbering all non-svn, non-dependency, non-clobberable files"
      
      # get all the '?|M   /some/path' lines from svn status, and return array of paths
      svn_status = silent_sh("svn status #{path}").split("\n")
      to_remove = svn_status.select{|l| l =~ /^\?/}.collect{|l| l.sub(/^\?\s*/,'')}
      to_revert = svn_status.select{|l| l =~ /^M/}.collect{|l| l.sub(/^M\s*/,'')}

      # exclude dependency paths from to_remove
      dep_paths = dependencies.collect(&:path)
      to_remove.reject! {|path| dep_paths.include?(path)}
      
      # exclude do_not_clobber paths from to_remove and to_revert
      to_keep = to_keep.collect{|path| Dir[path]}.flatten
      to_remove -= to_keep
      to_revert -= to_keep
      
      # remove the unknown paths
      to_remove.each {|path| silent_sh "rm -rf #{path}"}
      
      # revert the unkown paths
      to_revert.each {|path| silent_sh "svn revert #{path}"}
    end
  end
  
  class SvnDependency < Dependency
    attr_accessor :url
  
    def initialize(attrs)
      super
      self.updateable = !attrs.delete(:tagged?) if attrs[:tagged?]
      self.url = attrs[:url] or raise "Svn dependency requires :url in #{attrs.inspect}"
    end
    
    def install
      puts_silent_sh "svn co #{url} #{path}" unless super
    end

    def verify
      super
      if `svn info #{path}` =~ /^URL: (.*)/
        actual_url = $1
        actual_url == url or raise "#{name} has moved to #{url} (it points to #{actual_url}). Please remove #{path} and run rake dependencies:install."
      end
    end

    def update
      unless super
        silent_sh "svn cleanup #{path}"
        puts_silent_sh "svn up #{path}"
      end
    end
  end
end