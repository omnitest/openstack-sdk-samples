module Pacto
  module Extensions
    module Loaders
      class YamlOrJsonLoader
        YAML_EXTENSIONS = %w{.yml .yaml}
        def self.load(file)
          raw_data = File.read file
          if YAML_EXTENSIONS.include? File.extname(file)
            YAML::load(raw_data)
          else
            MultiJson.load(raw_data)
          end
        end
      end
    end
  end
end
