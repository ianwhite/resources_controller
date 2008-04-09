module PreCommit
  module Support
  protected
    # invokes a rake task
    def rake_invoke(task_name)
      Rake::Task[task_name].invoke
    end

    # runs rake task in a subshell, raising an error if it fails.  E.g:
    #  rake_sh('db:migrate', '-w', :RAILS_ENV => 'test')
    #
    # if :in is specified, then the subshell cds into that directory before
    # running the rake task.
    def rake_sh(task_name, *options)
      opts_hash = options.extract_options!
      in_dir = opts_hash.delete(:in)
      env = opts_hash.collect{|k,v| "#{k}=#{v}"}.join(' ')
      rake = (PLATFORM == "i386-mswin32") ? "rake.bat" : "rake"
      options |= ['--trace']
      cd_cmd = in_dir ? "cd #{in_dir}; " : ""
      cmd = "#{rake} #{task_name} #{env} #{options.join(' ')}"
      returning silent_sh(cd_cmd + cmd) do |output|
        raise "ERROR while running rake: #{cmd} #{"(in: #{in_dir})" if in_dir}" if shell_error?(output)
      end
    end

    # run sh command, returning output, use shell_error?(output) to test for success
    def silent_sh(cmd)
      output = nil
      IO.popen(cmd) do |io|
        output = io.read
      end
      output
    end
    
    # just like silent_sh, put it prints the command as well
    def puts_silent_sh(cmd)
      puts cmd
      silent_sh cmd
    end
    
    def shell_error?(output)
      output =~ /ERROR/n || error_code?
    end

    def error_code?
      $?.exitstatus != 0
    end
  end
end