require 'json'
module Crosstest
  module Skeptic
    module Spies
      class Pacto < Crosstest::Skeptic::Spy
        module Reports
          module Helpers
            def as_json(table)
              JSON.dump(table)
            end

            def slug(label)
              label.gsub('.', '_').gsub('-', '_')
            end

            def projects
              Crosstest.projects.map do |project|
                slug(project.name)
              end
            end

            def results
              rows = []
              supported = YAML.load(File.read('supported.yaml'))
              contracts = ::Pacto.load_contracts('pacto/swagger', nil, :swagger)
              services = supported # start w/ claims of supported services
              grouped_scenarios = Crosstest.manifest.scenarios.group_by{|s| s.psychic.name }
              Crosstest.projects.each do |project|
                services[project.name] ||= {}
                grouped_scenarios[project.name].each do |c|
                  begin
                    c[:spy_data][:pacto][:detected_services].each do |s|
                      services[project.name][s] = 'Tested'
                      # services[project.name][s] ||= 0
                      # services[project.name][s] += 1
                    end
                  rescue KeyError, NoMethodError
                  end
                end
              end

              # grouped_scenarios = contracts.group_by { |contract| [challenge.suite, challenge.name] }
              # grouped_scenarios.each do |(suite, name), scenarios|
              contracts.each do |contract|
                product, service = contract.name.split(' - ')
                row = {
                  product: product,
                  service: service
                }
                Crosstest.projects.each do |project|
                  row[slugify(project.name)] = services[project.name][contract.name]
                end
                rows << row
              end
              rows
            end
          end
        end

        class DashboardReport < Thor::Group
          include Crosstest::Core::FileSystem
          include Thor::Actions
          include Reports::Helpers

          class_option :destination, default: 'reports/'

          class << self
            attr_accessor :tabs

            def tab_name
              'Services'
            end

            def tab_target
              'services.html'
            end

            def source_root
              File.dirname(__FILE__)
            end
          end

          def projects
            Crosstest.projects.map do |project|
              slug(project.name)
            end
          end

          def report_name
            @report_name ||= self.class.name.downcase.split('::').last
          end

          def set_destination_root
            self.destination_root = options[:destination]
          end

          def copy_base_structure
            @tabs = self.class.tabs
            @active_tab = self.class.tab_name
            directory 'files', '.'
          end
        end
      end
    end
  end
end
