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
            contracts = ::Pacto.load_contracts('pacto/swagger', nil, :swagger)
            results = []
            # grouped_challenges = contracts.group_by { |contract| [challenge.suite, challenge.name] }
            # grouped_challenges.each do |(suite, name), challenges|
            contracts.each do |contract|
              product, service = contract.name.split(' - ')
              row = {
                product: product,
                service: service
              }
              # Polytrix.implementors.each do |implementor|
              #   challenge = challenges.find { |c| c.implementor == implementor }
              #   row[slug(implementor.name)] = status(challenge)
              # end
              results << row
            end
            results
          end
        end
      end

      class SummaryReport < Thor::Group
        include Polytrix::Core::FileSystemHelper
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
