autoload :Nokogiri, 'nokogiri'
autoload :CSV, 'csv'
autoload :FileUtils, 'fileutils'
require 'pacto'

namespace :confluence do
  desc 'Generate a CSV file from the confluence wiki'
  task :html2csv do
    raise 'You need to save the confluence page as matrix.html first' unless File.exists? 'matrix.html'

    html = File.read('matrix.html')
    doc = Nokogiri::HTML(html)
    nbsp = Nokogiri::HTML("&nbsp;").text

    CSV.open("matrix.csv", "wb") do |csv|
      doc.css("table:contains('Product') tr").each do |row|
        csv << row.css('td').map do |cell|
          cell.text.gsub("\n", ' ').gsub('"', '\"').gsub(/(\s){2,}/m, '\1').gsub(nbsp, ' ')
        end
      end
    end
    puts 'Created matrix.csv'
  end

  desc 'Cleans up the CSV, filling the product column and removing non-standard statuses'
  task :clean_csv do
    updated_csv = CSV.open('matrix.csv.tmp', 'wb')

    last_product = nil
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

      updated_csv << row
    end
    updated_csv.flush
    updated_csv.close
    FileUtils.move('matrix.csv.tmp', 'matrix.csv')
    puts 'Cleaned matrix.csv'
  end

  desc 'Convert to polytrix test results'
  task :csv2polytrix do
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
