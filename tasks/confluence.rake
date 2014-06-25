autoload :Nokogiri, 'nokogiri'
autoload :CSV, 'csv'
autoload :FileUtils, 'fileutils'

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
      next if feature.empty?
      unless row.header_row?
        row.each do |header, value|
          if header == 'Product'
            product = product.empty? ? last_product : product
            row['Product'] = last_product = product
          end

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
    manifest = Polytrix::Manifest.new

    CSV.foreach("matrix.csv", headers: :first_row) do |row|
      # WIP
      product = row['Product']
      feature = row['Feature']
      print "Searching test manifest for product: #{product}, feature: #{feature}"
      challenge = Polytrix.manifest.find_challenge(product, feature)

      puts challenge.nil? ? '' : " - found!"
      if challenge
        row.each do |header, value|
          next if %w(Product Feature).include? header

          if value == 'done'
            validation = Polytrix::Validation.new(validated_by: 'csv', result: 'passed')
            puts "Adding validation for #{header}: #{validation.inspect}"
          end
        end
      end
    end
  end
end
