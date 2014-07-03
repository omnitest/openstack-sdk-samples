require 'goliath'
require 'em-synchrony'
require 'em-synchrony/em-http'

class PactoServer < Goliath::API
  use ::Rack::ContentLength

  def port
    env.config[:port]
  end

  def on_body(env, data)
    env.logger.info 'received data: ' + safe_log(data)
    (env['async-body'] ||= '') << data
  end

  def response (env)
    path = env[Goliath::Request::REQUEST_PATH]
    host = env['HTTP_HOST'].gsub(".dev:#{port}", '.com')
    headers = env['client-headers']
    begin
      uri = normalize_uri(env, "https://#{host}#{path}")
      env.logger.info 'forwarding to: ' + uri
      safe_headers = headers.reject {|k,v| ['host', 'content-length', 'transfer-encoding'].include? k.downcase }
      env.logger.debug "filtered headers: #{safe_headers}"
      # request_body = env[Goliath::Request::RACK_INPUT].read
      request_body = env['async-body']
      request_method = env['REQUEST_METHOD'].downcase
      em_request_method = "a#{request_method}".to_sym
      em_request_options = {:head => safe_headers, :query => env['QUERY_STRING']}
      env.logger.debug "sending #{request_method} request"
      unless request_body.nil?
        em_request_options.merge!({:body => request_body})
        env.logger.debug "with request body"
      end

      resp = EM::Synchrony.sync EventMachine::HttpRequest.new(uri).send(em_request_method, em_request_options)
      raise resp.error if resp.error

      code = resp.response_header.http_status
      safe_response_headers = normalize_headers(resp.response_header).reject {|k,v| ['connection', 'content-encoding', 'content-length', 'transfer-encoding'].include? k.downcase}
      body = proxy_rewrite(resp.response)

      env.logger.debug "response headers: #{safe_response_headers}"
      env.logger.debug "response body: #{safe_log(body)}"
      [code, safe_response_headers, body]
    rescue => e
      env.logger.warn "responding with error: #{e.message}"
      [500, {}, e.message]
    end
  end

  def normalize_uri env, uri
    if uri[-1] == '/'
      env.logger.warn 'Normalizing uri with trailing /, this may be detected as a consistency issue in the future'
      uri = uri[0..-2]
    end
    uri
  end

  def normalize_headers headers
    headers.inject({}) do |res, elem|
      key = elem.first.dup
      value = elem.last
      key.gsub!('_', '-')
      key = key.split('-').map {|w| w.capitalize}.join '-'
      res[key] = value
      res
    end
  end

  def proxy_rewrite body
    # Make sure rels continue going through our proxy
    body.gsub('.com', ".dev:#{port}").gsub(/https\:([\w\-\.\\\/]+).dev/, 'http:\1.dev')
  end

  def options_parser(opts, options)
    options[:strict] ||= false
    options[:directory] ||= "contracts"
    opts.on('-l', '--live', 'Send requests to live services (instead of stubs)') { |val| options[:live] = true }
    opts.on('-g', '--generate', 'Generate Contracts from requests') { |val| options[:generate] = true }
    opts.on('-V', '--validate', 'Validate requests/responses against Contracts') { |val| options[:validate] = true }
    opts.on('-m', '--match-strict', 'Enforce strict request matching rules') { |val| options[:strict] = true }
    opts.on('-x', '--contracts_dir DIR', 'Directory that contains the contracts to be registered') { |val| options[:directory] = val }
    opts.on('-H', '--host HOST', 'Host of the real service, for generating or validating live requests') { |val| options[:backend_host] = val }
    opts.on('--stenographer-log-file', 'Location for the stenographer log file') { |val| options[:stenographer_log_file] = val }
  end

  def on_headers(env, headers)
    env.logger.info 'proxying new request: ' + headers.inspect
    env['client-headers'] = headers
  end

  def safe_log(string_to_log)
    if string_to_log.ascii_only?
     string_to_log
    else
      "(Supressed logging of non-ASCII content)"
    end
  end
end
