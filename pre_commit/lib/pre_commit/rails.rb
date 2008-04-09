module PreCommit
  module Rails
    def self.included(base)
      base.class_eval do
        include Svn
        cattr_accessor :db_adapter
        self.db_adapter = ENV['DB_ADAPTOR'] || 'sqlite3'
        self.do_not_clobber << 'config/database.yml'
      end
    end

    def verify_db_config
      db_config.verify rescue (raise "DB config: config/database.yml is missing.\nPlease run rake install_db_config [DB_ADAPTOR=mysql|sqlite3]")
    end
    
    def install_db_config
      db_config.install
    end
    
  protected
    def railses
      @railses ||= dependencies.select {|dep| dep.class == PreCommit::RailsDependency}
    end
    
    def with_railses(description = nil, &block)
      verify_db_config
      errors = []
      railses.each do |rails|
        with_rails(rails, description, &block) rescue (errors << [rails.name, $!])
      end
      errors.size == 0 or raise "\n#{description} failed against: #{errors.collect(&:first).to_sentence}\n#{errors.collect{|k,v| "- #{k}: #{v}"}.join("\n")}"
    end
    
    def with_rails(rails, description = nil, &block)
      puts "#{'#'*78}\nrunning: #{description} (against #{rails.name})\n#{'#'*78}"
      link_rails(rails)
      rails.run_before
      rake_sh('rails:update')
      rake_sh('db:create:all') rescue nil
      rake_sh('db:test:prepare')
      yield
    ensure
      puts "Cleaning up ..."
      rails.run_after
      clobber_using_svn
    end
    
    def link_rails(rails)
      silent_sh "rm -f vendor/rails; ln -s ../#{rails.path} vendor/rails"
    end
    
    def db_config
      @db_config ||= FileDependency.new(:actor => actor, :name => "DB Config", :path => "config/database.yml", :src => "config/database.#{db_adapter}.yml")
    end
  end
  
  # A RailsDependency is just an SVN dependency with some attrs for running
  # code before and after
  class RailsDependency < SvnDependency
    attr_accessor :before, :after

    def initialize(attrs = {})
      super
      self.before, self.after = attrs[:before], attrs[:after]
    end
    
    def run_before
      before and before.is_a?(Proc) ? instance_eval(&before) : eval(before)
    end
    
    def run_after
      after and after.is_a?(Proc) ? instance_eval(&after) : eval(after)
    end
  end
end