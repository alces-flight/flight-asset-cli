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
  # Allow the Config base classes to be switched out
  Config ||= Class.new(Hash)

  class Config
    def self.property(key, default: nil, required: false)
      key = key.to_sym
      requires[key] = true if required

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

    def self.requires
      @requires ||= {}
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
    end

    property :base_url, default: 'https://center.alces-flight.com/api/v1'
    property :create_dummy_group_name, default: 'ignore-me'
    property :jwt, default: ''

    property :component_id, required: true

    property :log_path
    property :log_level, default: 'error'

    def development?
      log_level == 'development'
    end

    def configured?
      keys = self.class.requires
                 .keys
                 .map { |k| [k, send(k)] }
                 .select { |_, v| v.nil? }
                 .to_h
                 .keys

      keys.empty?
    end

    def log_level_const
      case log_level
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
      when 'development'
        Logger::DEBUG
      end
    end

    def log_path_or_stderr
      if development?
        $stderr
      elsif log_path
        FileUtils.mkdir_p File.dirname(log_path)
        log_path
      else
        $stderr
      end
    end

    def logger
      @logger ||= Logger.new(log_path_or_stderr).tap do |l|
        if level = log_level_const
          l.level = level
        else
          $stderr.puts "Unrecognised log_level: #{log_level}"
          exit 1
        end
      end
    end

    # Defines the CACHE last
    Config::PATH ||= File.expand_path('../../etc/config.yaml', __dir__)
    Config::CACHE = File.exists?(PATH) ? read(PATH) : new
    Config::REFERENCE_PATH = File.expand_path('../../etc/config.reference.yaml', __dir__)
    Config::REFERENCE_OPTS = YAML.load(File.read(REFERENCE_PATH))
  end
end

