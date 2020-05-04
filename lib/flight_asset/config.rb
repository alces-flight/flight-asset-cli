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
  class ConfigDSL
    KeyDSL = Struct.new(:klass, :key) do
      def summary(value)
        klass.summaries[key]
      end

      def description(value)
        klass.descriptions[key] = value
      end

      def default(value)
        klass.defaults[key] = value
      end

      def required
        klass.requires[key] = true
      end

      def whilelist(*args)
        klass.whitelists[key] = args
      end
    end

    module ClassMethods
      def keys
        @keys ||= []
      end

      def requires
        @requires ||= {}
      end

      def summaries
        @summaries ||= {}
      end

      def descriptions
        @descriptions ||= {}
      end

      def defaults
        @defaults ||= {}
      end

      def whitelists
        @whitelists ||= {}
      end

      def config(key, &b)
        sym = key.to_sym
        self.keys << sym
        KeyDSL.new(self, sym) { |k| k.instance_exec(&b) if b }
        define_method(sym) { self[sym] }
      end
    end

    module InstanceMethods
      def initialize(**data)
        @__data__ = data.map { |k, v| [k.to_sym, v] }.to_h
      end

      def [](raw_key)
        key = raw_key.to_sym
        v = __data__.key?(key) ? __data__[key] : self.class.defaults[key]
        if v.respond_to?(:empty?) && v.empty?
          nil
        else
          v
        end
      end

      private

      def __data__
        @__data__ || {}
      end
    end

    def self.build(reference_path, config_path, &b)
      Class.new do
        extend ClassMethods
        include InstanceMethods

        self.class_eval(File.read reference_path)
        self.class_exec(&b) if b
      end.tap do |klass|
        data = if File.exists?(config_path)
          YAML.load(File.read(config_path), symbolize_names: true)
        else
          {}
        end
        klass.const_set('CACHE', klass.new(**data))
      end
    end
  end

  # Define the reference and config paths. The config_path if dynamic
  # allowing it to be moved
  REFERENCE_PATH = File.expand_path('../../etc/config.reference', __dir__)
  CONFIG_PATH ||= File.expand_path('../../etc/config.yaml', __dir__)

  # Constructs the Config class and cache
  Config = ConfigDSL.build(REFERENCE_PATH, CONFIG_PATH) do
    def development?
      log_level == 'development'
    end

    def missing_keys
      self.class.requires
                .keys
                .map { |k| [k, send(k)] }
                .select { |_, v| v.nil? }
                .to_h
                .keys
    end

    def configured?
      missing_keys.empty?
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
  end

  Config::COMMENT_BLOCK = <<~CONF
    # This config has been auto generated!
    #
    # Any modifications to the configuration values will be preserved
    # However comments will be removed the next time this file is updated
  CONF
end

