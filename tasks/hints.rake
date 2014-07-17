autoload :Nokogiri, 'nokogiri'
autoload :CSV, 'csv'
autoload :FileUtils, 'fileutils'

require 'hashie/extensions/deep_merge'
require 'hashie/extensions/deep_fetch'

class Hints < Hashie::Mash
  include Hashie::Extensions::DeepMerge
  extend Hashie::Extensions::DeepFetch

  # def self.deep_find(obj,key,value)
  #   if obj.respond_to?(:key?) && obj.key?(key)
  #     obj[key] == value
  #   elsif obj.respond_to?(:each)
  #     r = nil
  #     obj.find{ |*a| r=deep_find(a.last,key, value) }
  #     r
  #   end
  # end
end

namespace :hints do
  desc 'Extract hints from HTML api-ref'
  task :html2hints do
    hints = Hints.new
    ref_files = Dir['api-ref/*.html']
    raise 'You need to save api-ref HTML in api-ref/' if ref_files.empty?
    ref_files.each do | ref_file |
      next if ref_file =~ /email-and-apps/ # Not an API we're testing
      extract_hints ref_file, hints
    end
    File.open('hints.yaml', 'wb') do |f|
      f.write YAML.dump('hints' => hints.to_hash)
    end
  end
end

def nbsp
  @nbsp ||= Nokogiri::HTML("&nbsp;").text
end

def strip_all(string)
  string.gsub(/\s+/, ' ').gsub("\u200b", '').strip
end

def server_for(api)
  if api == 'Object Storage'
    '{server}clouddrive.com'
  else
    '{server}api.rackspacecloud.com'
  end
end

def name_for(http_method, resource, path)
  # tokens = path.split('/').keep_if {|f| f =~ /\A\{?\w+\}?\Z/} # Gets rid of versions, IDs
  desc = path.split('/').map do |token|
    next unless token =~ /\A\{?[-\w]+\}?\Z/ # Remove IDs, some version strings
    next if token =~ /\Av[\d\.]+\Z/ # Remove remaining version strings
    next if token == '{tenant_id}'
    token = token.delete '{}'
  end.compact.join ' '
  "#{http_method} #{desc}"
end

def extract_hints(file, hints)
  doc = Nokogiri::HTML(File.read(file))
  doc.css('.api-documentation > div').each do |api|
    api_title = strip_all(api.css('h2').text)
    api_title.gsub!(/ API.*/, '')
    hints[api_title] ||= {}
    hints[api_title]['server'] = server_for(api_title)
    hints[api_title]['services'] ||= {}

    resources = api.css('.subhead').map do |r|
      strip_all r.text
    end

    api.css('.doc-entry').each do |service|
      resource = strip_all(service.parent.css('.subhead > h3').text)
      entry = service.first_element_child
      http_method, uri_template, description = entry.css('div').map do |elem|
        strip_all(elem.text)
      end
      short_name = strip_all(entry.css('div > strong').text)
      uri_template.prepend '/' unless uri_template.start_with? '/'
      next if short_name.empty? # These are bugs in clouddocs-mavne-plugin, causing blank doc-entries to show up
      # puts "Path collision: #{resource} #{short_name} - #{uri_template}" if Hints.deep_find hints, :path, uri_template
      puts "Key collision: #{resource} #{short_name}" if hints[api_title]['services'].has_key? short_name
      hints[api_title]['services'][short_name] = {
        'http_method' => http_method,
        'path' => uri_template
      }
    end
  end
  hints
end
