require 'fileutils'

namespace :documentation do
  namespace :generate do
    desc 'Generate the Feature Matrix dashboard'
    task :dashboard do # => [:copy_src, :annotated] do
      $LOAD_PATH << 'spec'
      require 'spec_helper'
      require 'matrix_formatter/assets/generator'
      require 'matrix_formatter/formatters/html5_report_writer'

      asset_generator_options = {
        extra_resource_paths: ['lib/formatter/resources']
      }
      asset_generator = MatrixFormatter::Assets::Generator.new asset_generator_options
      asset_generator.generate

      output = File.open('docs/source/index.html', 'w')
      options = { view: 'angular.html.slim', layout: 'default_layout.html.slim' }
      formatter = MatrixFormatter::Formatters::HTML5ReportWriter.new output, options
      formatter.parse_results Dir['reports/matrix*.json']
      formatter.write_report
      output.close
    end

    desc 'Generate documentation with middleman'
    task :middleman do
      Dir.chdir 'docs' do
        Bundler.with_clean_env do
          sh 'bundle install'
          sh 'bundle exec middleman build'
        end
      end
    end

    desc 'Generate all documentation'
    task all: [:dashboard, :middleman]
  end

  desc 'Publish generated documentation to cloudfiles'
  task :publish do # => 'generate:all' do
    credentials = "--username=#{ENV['RAX_PUBLISH_USERNAME']} --api-key=#{ENV['RAX_PUBLISH_API_KEY']}"
    target = '--region=ord --container=drg_dashboard'
    command = "bundle exec dpl --provider=cloudfiles --skip_cleanup #{credentials} #{target}"
    # Need to fix (or stop using) AssetGenerator
    FileUtils.cp_r 'docs/assets', 'docs/build'
    FileUtils.cp_r 'docs/fonts', 'docs/build'
    Dir.chdir 'docs/build' do
      sh command
    end
  end
end
