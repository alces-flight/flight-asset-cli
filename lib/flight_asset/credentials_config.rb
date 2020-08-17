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
  class CustomMiddlewareChecks
    ResponseHandler = Struct.new(:app, :res) do
      # Checks if the 404 was "likely" caused by an invalid JWT
      def check_token
        return unless res.status == 404
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

      def raise_if_known_422
        return unless res.status == 422

        # Errors if the x or y capacity is bad
        if xy_capacity
          case code
          when 'not_a_number'
            raise ClientError, <<~ERROR.chomp
              The #{xy_capacity} must be a number
            ERROR
          when 'greater_than_or_equal_to'
            raise ClientError, <<~ERROR.chomp
              The #{xy_capacity} must be greater than zero
            ERROR
          end
        end

        # Errors if their is an issue with the parent
        if parent_container? && code == 'position range overlaps with another item in the parent container'
          raise ClientError, <<~ERROR.chomp
            Another container or asset is already using the specified range.
            Run the following for more details:
            #{Paint["#{Config::CACHE.app_name} show-container PARENT_CONTAINER", :yellow]}
          ERROR
        end

        if xy_end_position
          if code == 'greater_than'
            raise ClientError, <<~ERROR.chomp
              The #{xy_end_position} end position must be greater than the #{xy_end_position} start position
            ERROR
          elsif code == 'less_than_or_equal_to'
            raise ClientError, <<~ERROR.chomp
              The #{xy_end_position} end position exceeds the maximum size of the parent
            ERROR
          end
        end
      end

      ##
      # Note: The output is meant to be human readable not machine readable
      #       (beyond strings being truthy and nil falsely)
      # @returns [String] if the error was due to the xCapacity or yCapacity
      # @returns [Nil] if the error was not due to the XCapacity ir yCapacity
      def xy_capacity
        case pointer
        when '/data/relationships/xCapacity/data'
          'x capacity'
        when '/data/relationships/yCapacity/data'
          'y capacity'
        else
          nil
        end
      end

      ##
      # @returns [String] if the error was due to the xEndPosition or yEndPosition
      # @returns [Nil] if the error was not due to the xEndPosition or yEndPosition
      def xy_end_position
        case pointer
        when "/data/relationships/xEndPosition/data"
          'x'
        when "/data/relationships/yEndPosition/data"
          'y'
        else
          nil
        end
      end

      ##
      # Returns true if the error was due to the parent container
      def parent_container?
        pointer == '/data/relationships/parentContainer/data'
      end

      def pointer
        @pointer ||= res.body['errors'].first['source']['pointer']
      rescue
        # noop
      end

      def code
        @code ||= res.body['errors'].first['code']
      rescue
        # noop
      end
    end

    attr_reader :jwt

    def initialize(app, jwt:)
      @app = app
      @jwt = jwt
    end

    def call(env)
      env.request_headers['Authorization'] = "Bearer #{jwt}"
      @app.call(env).tap do |res|
        ResponseHandler.new(@app, res).tap(&:check_token).tap(&:raise_if_known_422)
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
        c.use CustomMiddlewareChecks, jwt: jwt!
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

