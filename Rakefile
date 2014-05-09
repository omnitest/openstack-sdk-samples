require 'polytrix'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

NOT_SETUP = "You need to set RAX_USERNAME and RAX_API_KEY env vars in order to run tests"

task :check_setup do
  fail NOT_SETUP unless ENV['RAX_USERNAME'] && ENV['RAX_API_KEY']
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
        if is_windows?
          system "PowerShell -NoProfile -ExecutionPolicy Bypass .\\scripts\\bootstrap"
        else
          system "scripts/bootstrap"
        end
      end
    end
  end
end

namespace :documentation do
  desc 'Generate the Feature Matrix dashboard'
  task :dashboard do # => [:copy_src, :annotated] do
    $: << 'spec'
    require  'spec_helper'
    require "matrix_formatter/assets/generator"
    require "matrix_formatter/formatters/html5_report_writer"
    require 'fileutils'

    asset_generator_options = {
      :extra_resource_paths => ['lib/formatter/resources']
    }
    asset_generator = MatrixFormatter::Assets::Generator.new asset_generator_options
    asset_generator.generate

    output = File.open("docs/dashboard.html", 'w')
    options = {:view => 'angular.html.slim', :layout => 'default_layout.html.slim'}
    formatter = MatrixFormatter::Formatters::HTML5ReportWriter.new output, options
    matrix = formatter.parse_results Dir['reports/matrix*.json']
    # puts MultiJson.encode formatter.matrix
    formatter.write_report
    output.close

    fail "Combined results contain failures - check the reports" if formatter.has_failures?
  end
end

def is_windows?
  RbConfig::CONFIG['host_os'] =~ /mswin(\d+)|mingw/i
end
