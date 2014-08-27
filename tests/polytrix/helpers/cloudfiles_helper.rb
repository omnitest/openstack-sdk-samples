require 'fog'

def build type, env = {}
  case type
  when :file
    build_file env
  else
    raise ArgumentError.new "Don't know how to be a #{type}"
  end
end

def build_file env
  without_webmock do
    service = Fog::Storage.new({
      :provider             => 'rackspace',
      :rackspace_username   => env['RAX_USERNAME'],
      :rackspace_api_key    => env['RAX_API_KEY'],
      :rackspace_region     => env['RAX_REGION']
    })

    directory = service.directories.create :key => 'asdf'
    file = directory.files.create :key => 'asdf', :body => 'efgh'
  end
end

def without_webmock
  WebMock.disable!
  ret_val = yield
  WebMock.enable!
  ret_val
end
