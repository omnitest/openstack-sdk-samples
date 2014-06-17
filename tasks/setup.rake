NO_CREDS    = 'You need to set RAX_USERNAME and RAX_API_KEY env vars in order to run tests'

task :check_setup do
  fail NO_CREDS unless ENV['RAX_USERNAME'] && ENV['RAX_API_KEY']
end

desc 'Remove reports and other generated artifacts'
task :clean do
  FileUtils.rm_rf 'docs'
  FileUtils.rm_rf 'reports'
end

desc 'Fetch dependencies for each SDK'
task :bootstrap do
  Bundler.with_clean_env do
    Dir['sdks/*'].each do |sdk_dir|
      Dir.chdir sdk_dir do
        if windows?
          system 'PowerShell -NoProfile -ExecutionPolicy Bypass .\\scripts\\bootstrap'
        else
          system 'scripts/bootstrap'
        end
      end
    end
  end
  FileUtils.cp_r 'doc-src/', 'docs'
end

def windows?
  RbConfig::CONFIG['host_os'] =~ /mswin(\d+)|mingw/i
end
