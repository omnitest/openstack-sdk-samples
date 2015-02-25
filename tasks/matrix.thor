autoload :Nokogiri, 'nokogiri'
autoload :CSV, 'csv'
autoload :FileUtils, 'fileutils'
require 'pacto'

class Matrix < Thor
  include Thor::Actions

  desc 'process [HTML_FILE]', 'Combines all steps for transforming matrix.html -> more parsable formats'
  def process(html_file = 'matrix.html')
    thor 'matrix:extract', html_file
    thor 'matrix:normalize'
    thor 'matrix:enhance'
  end

  desc 'extract [HTML_FILE]', 'Generate a CSV file from the confluence wiki'
  def extract(html_file = 'matrix.html')
    abort 'You need to save the SDK Matrix wiki page as matrix.html first' unless File.exists? html_file

    html = File.read(html_file)
    doc = Nokogiri::HTML(html)
    nbsp = Nokogiri::HTML("&nbsp;").text

    add_file 'matrix.csv' do
      CSV.generate do |csv|
        doc.css("table:contains('Product') tr").each do |row|
          csv << row.css('td').map do |cell|
            cell.text.gsub("\n", ' ').gsub('"', '\"').gsub(/(\s){2,}/m, '\1').gsub(nbsp, ' ')
          end
        end
      end
    end
  end

  desc 'normalize [csv_file]', 'Cleans up the CSV, filling the product column and removing non-standard statuses'
  def normalize(csv_file = 'matrix.csv')
    add_file 'matrix.csv' do
      last_product = nil
      CSV.generate do |csv|
        CSV.foreach("matrix.csv", headers: :first_row, return_headers: true) do |row|
          product = row['Product'].strip
          feature = row['Feature'].strip
          product = product.empty? ? last_product : product
          row['Product'] = last_product = product
          next if feature.empty?
          unless row.header_row?
            row.each do |header, value|
              unless %w(Product Feature).include? header
                done = value.strip =~ /\Adone\Z/i
                value = done ? 'done' : ''
                row[header] = value
              end
            end
          end

          csv << row
        end
      end
    end
  end

  desc 'enhance [CSV_FILE]', 'Enhances the CSV, merging in data from API docs'
  method_option :verbose, type: :boolean, default: 'false'
  def enhance(csv_file = 'matrix.csv')
    matched_operations, missing_operations, ignored_features = {}, [], []
    contracts = Pacto.load_contracts('pacto/swagger', nil, :swagger)
    add_file 'features.csv' do
      CSV.generate(:headers => :first_row) do |csv|
        CSV.foreach("matrix.csv", headers: :first_row, return_headers: true) do |row|
          csv << row.dup.headers.insert(2, 'operationId') if row.header_row?
          product = row['Product']
          feature = row['Feature']
          slugified_name = "#{product} - #{feature}"

          if feature.match(/\*|\^|\$/) # these aren't services
            ignored_features << slugified_name
            say_status :ignored, "#{slugified_name} does not correspond to a service", :yellow
            next
          end

          contract = contracts.find { |c| c.name.downcase == slugified_name.downcase }

          if contract
            enhanced_row = row.fields
            enhanced_row.insert(2, contract.id)
            csv << enhanced_row
            info = <<-eos
            Pacto contract for #{slugified_name}:
              id: #{contract.id}
              pattern: #{contract.request_pattern}
            eos
            say_status :found, info.strip
            matched_operations[slugified_name] = contract
            # This would be more accurate
            # contracts.delete contract
            # But we'll be more generous and delete duplicates
            contracts.delete_if {|c| c.name == contract.name }
          else
            if slugified_name.match(/.*(\.|\$|\^)/)
              ignored_features << slugified_name
              say_status :ignored, "#{slugified_name} is a non-service feature", :yellow
            else
              missing_operations << slugified_name
              say_status :missing, "Pacto contract for #{slugified_name}", :red
            end
          end
        end
      end
    end

    unused = contracts - matched_operations.values
    say "Summary:"
    say "  Matched: #{matched_operations.size}"
    say "  Ignored: #{ignored_features.size}"
    say "    " + ignored_features.join("\n    ")
    say "    "
    say "  Missing: #{missing_operations.size}"
    say "  Unused: #{unused.size}"
  end

  desc 'convert', 'Convert Matrix to omnitest friendly data format'
  def convert(csv_file = 'matrix.csv')
    supported = {}
    contracts = Pacto.load_contracts('pacto/swagger', nil, :swagger)
    CSV.foreach("matrix.csv", headers: :first_row) do |row|
      # WIP
      product = row['Product']
      feature = row['Feature']
      next if feature.match(/\*|\^/) # these aren't services
      print "Searching Pacto contracts for: #{product}, feature: #{feature}"
      slugified_name = "#{product} - #{feature}"
      contract = contracts.find { |c| c.name.downcase == slugified_name.downcase }
      puts contract.nil? ? ' - not found...' : " - found!"

      if contract
        row.each do |header, value|
          next if %w(Product Feature).include? header

          if value == 'done'
            supported[header] ||= {}
            supported[header][contract.name] = 'Supported'
            # supported[header][product] ||= {}
            # supported[header][product][feature] = 'Supported'
          end
        end
      end

      File.write('supported.yaml', YAML.dump(supported))
    end
  end
end
