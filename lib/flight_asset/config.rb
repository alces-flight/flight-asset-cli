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
require 'delegate'

module FlightAsset
  class ConfigDSL
    KeyDSL = Struct.new(:klass, :key) do
      def summary(value)
        klass.summaries[key] = value
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

      def volatile(value)
        klass.volatiles[key] = value
      end

      def whitelist(*args)
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

      def volatiles
        @volatiles ||= {}
      end

      def whitelists
        @whitelists ||= {}
      end

      def flags
        @flags ||= Hash.new do |h, k|
          h[k] = "--#{k.to_s.gsub('_', '-')}"
        end
      end

      # TODO: Make this settable
      def conversions
        Hash.new(:to_s)
      end

      def config(key, &b)
        sym = key.to_sym
        self.keys << sym
        KeyDSL.new(self, sym).tap { |k| k.instance_exec(&b) } if b
        define_method(sym) { self[sym] }
      end
    end

    class MetaConfig < SimpleDelegator
      attr_reader :instance

      def initialize(instance)
        @instance = instance
        super(instance.class)
      end

      def full_flags
        @full_flags ||= Hash.new do |_, flag|
        end
      end

      def flag_helps
        @flag_helps
      end

      def commander_option_helper(cmd)
        keys.each do |key|
          arg = if requires[key] && instance[key]
                  'FILLED'
                elsif requires[key]
                  'REQUIRED'
                else
                  'OPTIONAL'
                end
          full_flag = "#{flags[key]} #{arg}"

          full_msg = summaries[key].dup
          if instance.__data__.key?(key)
            current = instance[key]
            if current.nil?
              full_msg << "\nBLANK"
            else
              full_msg << "\nCURRENT: #{current}"
            end
          end
          full_msg << "\nDEFAULT: #{defaults[key]}" if defaults.key?(key)
          full_msg << "\nVALUES: #{whitelists[key].join(',')}" if whitelists.key?(key)
          full_msg << "\nVOLATILE: #{volatiles[key]}" if volatiles.key?(key)

          cmd.option "#{full_flag}", "#{full_msg}".chomp
        end

        keys.each do |key|
          reset_msg = if defaults.key?(key)
            "Revert to the default value"
          else
            "Revert to a blank value"
          end
          cmd.option "#{flags[key].sub('--', '--reset-')}", reset_msg
        end
      end

      def missing_keys_without_defaults
        requires.keys.select do |k|
          instance[k].nil? && !defaults.key?(k)
        end
      end

      def nil_required_defaulted_keys
        requires.keys.select { |k| defaults.key?(k) && instance[k].nil? }
      end

      def bad_whitelist_keys
        whitelists.map { |k, values| [k, values, instance[k]] }
                  .reject { |_k, _v, value| value.nil? }
                  .reject { |_, values, value| values.include?(value) }
                  .map { |key, _, _v| key }
      end

      def generate_error_messages
        [].tap do |errors|
          unless (missing = missing_keys_without_defaults).empty?
            errors << <<~ERROR.chomp
              The following flag(s) should not be blank:
              #{missing.map { |k| flags[k] }.join(' ')}
            ERROR
          end

          unless (requires = nil_required_defaulted_keys).empty?
            errors << <<~ERROR.chomp
              The following flag(s) should not override their defaults to be blank:
              #{requires.map { |k| flags[k] }.join(' ')}

              Did you mean?
              #{requires.map { |k| flags[k].sub('--', '--reset-') }.join(' ')}
            ERROR
          end

          unless (bads = bad_whitelist_keys).empty?
            msgs = bads.map do |k|
              "#{flags[k]} #{instance[k]} # VALID: #{whitelists[k].join(',')}"
            end
            errors << <<~ERROR.chomp
              The following flag(s) are invalid:
              #{msgs.join("\n")}
            ERROR
          end
        end
      end
    end

    module InstanceMethods
      attr_reader :__data__, :__converted__, :__meta__

      def initialize(**data)
        @__data__ = data.map { |k, v| [k.to_sym, v] }.to_h
        @__converted__ = {}
        @__meta__ = MetaConfig.new(self)
      end

      def [](raw_key)
        key = raw_key.to_sym
        if __converted__.key?(key)
          __converted__[key]
        else
          __converted__[key] = begin
            if __data__.key?(key) && [nil, ''].include?(__data__[key])
              nil
            elsif __data__.key?(key)
              __data__[key].send(self.class.conversions[key])
            else
              self.class.defaults[key]
            end
          end
        end
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
end

