RSpec.configure do |c|
  c.after(:each) { auto_teardown }
end

def auth_token
  @auth_token ||= Pacto::InvestigationRegistry.instance.investigations.map do | val |
    token = val.request.headers['X-Auth-Token']
  end.compact.reject(&:empty?).first
end

def auto_teardown
  # HACK: This should be simplified and moved to Pacto

  created_resources = auto_find_prg
  auto_delete created_resources, auth_token
end

REDIRECTS = [201, 202, (300...400).to_a.flatten]

def auto_find_prg
  # Find URLs that were the "Get" part of a Post-Redirect-Get pattern
  created_uris = Pacto::InvestigationRegistry.instance.investigations.map {|investigation|
    investigation.response.headers['Location'] if investigation.request.method == :post and REDIRECTS.include? investigation.response.status
  }.compact

  created_uris.map do | created_uri |
    Addressable::URI.parse created_uri
  end
end

def auto_delete uris, auth_token
  uris.group_by(&:site).each do | site, uris |
    connection = Excon.new(site)
    uris.each do | uri |
      puts "Removing #{uri}"
      connection.delete(:path => uri.path,
        :debug_request => true,
        :debug_response => true,
        :expects => [204],
        :headers => {
          "User-Agent" => "fog/1.18.0",
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "X-Auth-Token" => auth_token
        }
      )
    end
  end
end
