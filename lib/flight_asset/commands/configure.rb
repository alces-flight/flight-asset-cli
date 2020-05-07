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

module FlightAsset
  module Commands
    class Configure < Command
      def run
        # Extracts the existing config data
        old = cache.__data__

        # Refuse to update protect flags by default
        sym_opts = opts.keys.map(&:to_sym)
        reset_protects = Config.protects.keys.map { |k| :"reset_#{k}" }
        reset_vol_opts = sym_opts & reset_protects
        vol_opts = sym_opts & Config.protects.keys
        unless opts.allow_protected || [*reset_vol_opts, *vol_opts].empty?
          msgs = []
          unless vol_opts.empty?
            msgs << "The following flags are protected, please ensure:"
            vol_opts.each do |key|
              msgs << "#{Config.flags[key]}: #{Config.protects[key]}"
            end
            msgs << ''
          end
          unless reset_vol_opts.empty?
            msgs << 'The following will reset a protect flag:'
            msgs << reset_vol_opts.map { |k| Config.flags[k] }.join(' ')
            msgs << ''
          end
          msgs << 'Use the --allow-protected flag to proceed.'
          raise InternalError, msgs.join("\n")
        end

        # Extracts the merge data
        merge = Config.keys.each_with_object({}) do |k, memo|
          memo[k] = opts[k] if opts.key?(k)
        end

        # Extracts the reset data
        resets = Config.keys.select { |k| opts[:"reset_#{k}"] }

        # Creates the new data and config
        data = old.dup.merge(merge)
        resets.each { |k| data.delete(k) }
        config = Config.new(**data)

        # Sets the verb
        verb = File.exists?(CONFIG_PATH) ? 'Updated' : 'Created'

        # Validates the new config
        errors = config.__meta__.generate_error_messages
        if opts.force
          Config::CACHE.logger.error <<~ERRORS
            Force-#{verb} the config with the following errors:

            #{errors.join("\n\n")}
          ERRORS
        else
          raise InternalError, <<~ERROR unless errors.empty?
            The config has not been #{verb.downcase} as the following error(s) have occurred!
            Validation can be bypassed with the --force flag

            #{errors.join("\n\n")}
          ERROR
        end

        # Writes the config
        FileUtils.mkdir_p File.dirname(CONFIG_PATH)
        File.write CONFIG_PATH, <<~CONF
          # This config has been auto generated!
          #
          # Any modifications to the configuration values will be preserved
          # However comments will be removed the next time this file is updated

          #{YAML.dump(data)}
        CONF

        # Notifies the user
        #
        $stderr.puts "#{verb} Config: #{CONFIG_PATH}"
      end

      def cache
        Config::CACHE
      end
    end
  end
end
