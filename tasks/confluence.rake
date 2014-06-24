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
    csv = CSV.foreach("matrix.csv", headers: :first_row) do |row|
      product = row['Product'].strip
      product = product.empty? ? last_product : product
      row['Product'] = last_product = product
      updated_csv << row
    end
    updated_csv.flush
    updated_csv.close
    FileUtils.move('matrix.csv.tmp', 'matrix.csv')
    puts 'Cleaned matrix.csv'
  end
end
