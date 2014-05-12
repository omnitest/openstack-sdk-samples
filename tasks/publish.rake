namespace :publish do
  desc 'Publish generated documentation to cloudfiles'
  task :docs do # => [:copy_src, :annotated] do
    credentials = "--username=#{ENV['RAX_PUBLISH_USERNAME']} --api-key=#{ENV['RAX_PUBLISH_API_KEY']}"
    target = "--region=ord --container=sdk_dashboard"
    command = "bundle exec dpl --provider=cloudfiles --skip_cleanup #{credentials} #{target}"
    Dir.chdir 'docs' do
      sh command
    end
  end
end
