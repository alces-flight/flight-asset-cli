# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
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

#
# NOTE: This file MUST NOT have external GEM dependencies has it will be loaded
# before Bundler has been setup. As such any advanced config setup needs to be
# implemented manually
#
require 'yaml'
require 'logger'

module FlightAsset
  class Config < Hash
    def self.property(key, default: nil, required: false)
      key = key.to_sym
      required_keys << key

      define_method(key) do
        if (v = opts[key]) && !v.nil?
          v
        elsif default.respond_to?(:call)
          opts[key] ||= default.call
        else
          default
        end
      end
    end

    def self.required_keys
      @required_keys ||= []
    end

    def self.read(path)
      data ||= begin
        YAML.load(File.read(path), symbolize_names: true)
      rescue
        $stderr.puts "Failed to load config: #{Config::PATH}"
        exit 1
      end
      new(**data)
    end

    attr_reader :opts

    def initialize(**opts)
      @opts = opts

      keys = self.class.required_keys
                       .map { |k| [k, send(k)] }
                       .select { |_, v| v.nil? }
                       .to_h
                       .keys

      unless keys.empty?
        $stderr.puts <<~ERROR
          Failed to load configuration file as the following are required:
          #{keys.join(',')}
        ERROR
        exit 1
      end

      logger # Ensures the logger is setup
    end

    property :base_url, default: 'https://example.com/api/v1'
    property :jwt, default: ''
    property :component_id, required: true
    property :create_dummy_group_name, required: true

    property :log_path, default: ->() do
      $stderr.puts <<~MSG
        Logging to Standard Error! This can be disabled by setting the 'log_path'
      MSG
      $stderr
    end
    property :log_level, default: 'error'

    def debug?
      log_level == 'debug'
    end

    def logger
      @logger ||= Logger.new(log_path || $stderr).tap do |l|
        l.level = case log_level
        when 'fatal'
          Logger::FATAL
        when 'error'
          Logger::ERROR
        when 'warn'
          Logger::WARN
        when 'info'
          Logger::INFO
        when 'debug'
          Logger::DEBUG
        else
          $stderr.puts "Unrecognised log_level: #{log_level}"
          exit 1
        end
      end
    end

    # Defines the CACHE last
    CONFIG_PATH ||= nil
    Config::CACHE = CONFIG_PATH ? read(CONFIG_PATH) : new
  end
end

