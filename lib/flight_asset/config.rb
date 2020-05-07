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
    def self.build(reference_path, config_path, &b)
      Class.new do
        extend ClassMethods
        include InstanceMethods

        self.load_reference(reference_path)
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

    KeyDSL = Struct.new(:klass, :key) do
      def summary(value)
        klass.summaries[key] = value
      end

      def description(value)
        klass.descriptions[key] = value
      end

      def default(value, &b)
        klass.defaults[key] = value || b
      end

      def required
        klass.requires[key] = true
      end

      def protect(value)
        klass.protects[key] = value
      end

      def whitelist(*args)
        klass.whitelists[key] = args
      end

      def sensitive
        klass.sensitives[key] = true
      end

      def coerce(sym, &b)
        klass.coerces[key] = sym || b
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

      def defaults(&block)
        @defaults ||= {}
      end

      def protects
        @protects ||= {}
      end

      def whitelists
        @whitelists ||= {}
      end

      def sensitives
        @sensitives ||= {}
      end

      def flags
        @flags ||= Hash.new do |h, k|
          h[k] = "--#{k.to_s.gsub('_', '-')}"
        end
      end

      def coerces
        @coerces ||= Hash.new(:to_s)
      end

      # Handy short-hand to coerces, the internal result is intentionally
      # not being cached. This will be done on this instance
      def conversions
        @conversions ||= Hash.new do |_, key|
          sym_or_proc = coerces[key]
          if sym_or_proc.respond_to? :call
            sym_or_proc
          else
            ->(v) { v.send(sym_or_proc) }
          end
        end
      end

      def config(key, &b)
        sym = key.to_sym
        self.keys << sym
        KeyDSL.new(self, sym).tap { |k| k.instance_exec(&b) } if b
        define_method(sym) { self[sym] }
        define_method(:"#{sym}!") do
          value = self[sym]
          value.nil? ? conversions[key].call(nil) : value
        end
      end

      def load_reference(path)
        self.instance_eval(File.read(path), path, 0) if File.exists?(path)
      end
    end

    module InstanceMethods
      attr_reader :__data__, :__meta__

      def initialize(**data)
        @__data__ = data.map { |k, v| [k.to_sym, v] }.to_h
        @__meta__ = MetaConfig.new(self)
      end

      def [](raw_key)
        __cache__[raw_key.to_sym]
      end

      def __cache__
        @__cache__ ||= Hash.new do |hash, key|
          is_current = __data__.key?(key)
          value = if is_current
            self.class.conversions[key].call(__data__[key])
          else
            default = self.class.defaults[key]
            default.respond_to?(:call) ? default.call : default
          end

          # Force nil and empty string to be the same value
          hash[key] = (value == '' ? nil : value)
        end
      end
    end

    # Consider refactoring into a Commander::ConfigureCommandHelper ?
    class MetaConfig < SimpleDelegator
      attr_reader :instance

      def initialize(instance)
        @instance = instance
        super(instance.class)
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

          # Generate the "value" section
          if sensitives.key?(key)
            full_msg << "\nSENSITIVE"
          else
            current = instance[key]
            if current.nil?
              full_msg << "\nBLANK"
            elsif instance.__data__.key?(key)
              full_msg << "\nCURRENT: #{current}"
            end
          end

          # Generate the "default" section
          if defaults.key?(key)
            full_msg << "\nDEFAULT"
            if sensitives.key?(key)
              full_msg << ' - OVERRIDDEN' if instance.__data__.key?(key)
            else
              full_msg << " #{defaults[key]}"
            end
          end

          full_msg << "\nVALUES: #{whitelists[key].join(',')}" if whitelists.key?(key)
          full_msg << "\nPROTECTED: #{protects[key]}" if protects.key?(key)

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
  end

  # Define the reference and config paths. The config_path if dynamic
  # allowing it to be moved
  REFERENCE_PATH = File.expand_path('../../etc/config.reference', __dir__)
  CONFIG_PATH ||= File.expand_path('../../etc/config.yaml', __dir__)

  # Constructs the Config class and cache
  Config = ConfigDSL.build(REFERENCE_PATH, CONFIG_PATH) do
    def development?
      __data__[:development] ? true : false
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

    def log_path_or_stderr
      if log_level == 'disabled'
        '/dev/null'
      elsif log_path
        FileUtils.mkdir_p File.dirname(log_path)
        log_path
      else
        $stderr
      end
    end

    def logger
      @logger ||= Logger.new(log_path_or_stderr).tap do |log|
        next if log_level == 'disabled'

        # Determine the level
        level = case log_level
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
        end

        if level.nil?
          # Log bad log levels
          log.level = Logger::ERROR
          log.error "Unrecognized log level: #{log_level}"
        else
          # Sets good log levels
          log.level = level
        end
      end
    end
  end
end

