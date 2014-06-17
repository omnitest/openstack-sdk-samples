require 'pacto_server'
require 'goliath/test_helper'

module Polytrix
  module Runners
    module Middleware
      class Mimic

        def initialize(app, server_options)
          @app   = app
          # It's not currently possible to use both Mimic & Pacto
          # May need a custom proxy routing plugin for Pacto Server...
          Polytrix.manifest.global_env['OS_AUTH_URL'] = 'http://localhost:8901'
        end

        def call(env)
          @app.call(env)
        end
      end
    end
  end
end
