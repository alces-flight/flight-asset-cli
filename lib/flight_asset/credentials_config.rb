# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of Flight Asset.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Asset is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Asset. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Asset, please visit:
# https://github.com/alces-flight/alces-flight/flight-asset-cli
#==============================================================================

require 'jwt'
require 'paint'

module FlightAsset
  class JWTCheckMiddleware
    attr_reader :jwt

    def initialize(app, jwt:)
      @app = app
      @jwt = jwt
    end

    def call(env)
      env.request_headers['Authorization'] = "Bearer #{jwt}"
      @app.call(env).tap do |res|
        # Checks if the 404 was "likely" caused by an invalid JWT
        check_token if res.status == 404
      end
    end

    def check_token
      expiry = begin
        JWT.decode(jwt, nil, false).first['exp']
      rescue
        raise CredentialsError, <<~ERROR.chomp
          Your access token appears to be malformed and needs to be regenerated.
          Please take care when copying the token into the configure command:
          #{Paint["#{Config::CACHE.app_name} configure", :yellow]}
        ERROR
      end

      if expiry && expiry < Time.now.to_i
        raise CredentialsError, <<~ERROR.chomp
          Your access token has expired! Please regenerate it and run:
          #{Paint["#{Config::CACHE.app_name} configure", :yellow]}
        ERROR
      end
    end
  end

  class CredentialsConfig < ConfigBase
    config :component_id
    config :jwt

    # Quick check that can be done on config load
    def validate
      @validate = component_id? && jwt?
    end

    ##
    # NOTE: Eventually make network request here
    def validate!
      validate
    end

    def valid?
      if @validate.nil?
        validate
      else
        @validate ? true : false
      end
    end

    def headers
      {
        'Accept' => 'application/vnd.api+json',
        'Content-Type' => 'application/json'
      }
    end

    def url
      File.join(Config::CACHE.base_url!, Config::CACHE.api_prefix!)
    end

    def connection
      @connection ||= Faraday.new(url: url, headers: headers) do |c|
        c.use JWTCheckMiddleware, jwt: jwt!
        c.use Faraday::Response::Logger, Config::CACHE.logger, { bodies: true } do |l|
          l.filter(/(Authorization:)(.*)/, '\1 [REDACTED]')
        end
        c.request :json
        c.response :json, :content_type => /\bjson$/
        c.adapter :net_http
      end
    end
  end
end

