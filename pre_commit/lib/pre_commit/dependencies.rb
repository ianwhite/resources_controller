module PreCommit
  module Dependencies
    def self.included(base)
      base.class_eval do
        def self.dependencies=(dependencies)
          @@dependencies = dependencies
        end
        self.dependencies = []
      end
    end
    
    # return dependencies.  If they have not been set, initialize them with @@dependencies
    def dependencies
      self.dependencies = @@dependencies unless @dependencies
      @dependencies
    end
    
    def dependencies=(deps)
      @dependencies = returning DependencySet.new(actor) do |set|
        deps.each {|dep| set << dep}
      end
    end
    
    class DependencySet
      include Actor
      include Enumerable
      delegate :each, :to => '@dependencies'

      def initialize(actor)
        self.actor = actor
        @dependencies = []
      end

      def <<(dependency)
        dependency = Dependency.new(dependency) if dependency.is_a?(Hash)
        dependency.actor = self.actor
        @dependencies << dependency
        self
      end

      def clobber
        @dependencies.each {|d| sh "rm -rf #{d.path}"}
      end

      def install
        @dependencies.each(&:install)
      end

      def update
        @dependencies.each(&:update)
      end

      def verify
        errors = []
        @dependencies.each {|d| d.verify rescue (errors << $!)}
        errors.size == 0 or raise "\nThere are problems with dependencies:\n\n- #{errors.join("\n\n- ")}"
      end
    end
  end
  
  # Abstract dependency class
  class Dependency
    include Actor
    
    attr_accessor :path, :name, :updateable
  
    # Factory for dependency, if attrs hash has :type key, it will be used
    # to create the dependency by camelizing and adding 'Dependency'
    #
    # e.g. Dependency.new(:type => :svn, ...)  #=> SvnDependency.new(...)
    def self.new(attrs)
      if type = attrs.delete(:type)
        "PreCommit::#{type.to_s.camelize}Dependency".constantize.new(attrs)
      else
        super(attrs)
      end
    end
    
    def initialize(attrs)
      self.actor = attrs[:actor] if attrs[:actor]
      self.path = attrs[:path] or raise "Dependency requires :path attribute in #{attrs.inspect}"
      self.name = attrs[:name] || path
      self.updateable = attrs[:updateable]
    end
    
    def install
      puts "\nInstalling #{name} ..."
      returning File.exist?(path) do |success|
        puts "#{name} already installed in #{path}" if success
      end
    end

    def verify
      File.exist?(path) or raise "#{name} is missing.  Please run rake dependencies:install."
    end
    
    def update
      return true unless updateable?
      puts "\nUpdating #{name} ..."
    end
    
    def updateable?
      @updateable != false
    end
    
  protected
    # return true if the file names and modification times of passed directories are equal
    def dirs_equal?(dira, dirb)
      dir_signature(dira) == dir_signature(dirb)
    end
    
    # return an array of filenames and modification times for all regular contents of a directory
    def dir_signature(dir)
      sig = [File.size(dir).to_s, File.mtime(dir).to_s]
      sig + Dir["#{dir}/**/*"].collect{|f| [f.sub(dir,''), File.mtime(f).to_s]}.flatten.sort
    end
  end
  
  class FileDependency < Dependency
    attr_accessor :src
    
    def initialize(attrs)
      super
      self.src = attrs[:src] or raise "File dependency requires :src attributes in #{attrs.inspect}"
    end
    
    def install
      copy_directory unless super
    end

    def update
      unless super
        dirs_equal?(src, path) ? puts("No changes, not updated") : copy_directory
      end
    end
    
  protected
    def copy_directory
      silent_sh "rm -rf #{path}; mkdir -p #{File.dirname(path)}"
      puts_silent_sh "cp -pr #{src} #{path}"
    end
  end
end