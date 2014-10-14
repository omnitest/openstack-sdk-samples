require 'json'
module Polytrix
  module Spies
    class Pacto < Polytrix::Spy
      module Reports
        module Helpers
          def as_json(table)
            JSON.dump(table)
          end

          def slug(label)
            label.gsub('.', '_').gsub('-', '_')
          end

          def implementors
            Polytrix.implementors.map do |implementor|
              slug(implementor.name)
            end
          end

          def results
            rows = []
            contracts = ::Pacto.load_contracts('pacto/swagger', nil, :swagger)
            services = {}
            grouped_challenges = Polytrix.manifest.challenges.values.group_by(&:implementor)
            Polytrix.implementors.each do |implementor|
              services[implementor.name] = {}
              grouped_challenges[implementor].each do |c|
                begin
                  c[:spy_data][:pacto][:detected_services].each do |s|
                    services[implementor.name][s] ||= 0
                    services[implementor.name][s] += 1
                  end
                rescue KeyError, NoMethodError
                end
              end
            end

            # grouped_challenges = contracts.group_by { |contract| [challenge.suite, challenge.name] }
            # grouped_challenges.each do |(suite, name), challenges|
            contracts.each do |contract|
              product, service = contract.name.split(' - ')
              row = {
                product: product,
                service: service
              }
              Polytrix.implementors.each do |implementor|
                row[slugify(implementor.name)] = services[implementor.name][contract.name]
              end
              rows << row
            end
            rows
          end
        end
      end

      class DashboardReport < Thor::Group
        include Polytrix::Util::FileSystem
        include Thor::Actions
        include Reports::Helpers

        class_option :destination, default: 'reports/'

        def implementors
          Polytrix.implementors.map do |implementor|
            slug(implementor.name)
          end
        end

        def self.source_root
          File.dirname(__FILE__)
        end

        def report_name
          @report_name ||= self.class.name.downcase.split('::').last
        end

        def set_destination_root
          self.destination_root = options[:destination]
        end

        def copy_base_structure
          directory 'files', '.'
        end
      end
    end
  end
end
