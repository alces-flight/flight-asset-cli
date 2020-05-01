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
        # Extracts the data
        data = Config::REFERENCE_OPTS.keys.map do |key|
          [key, (opts[key.to_sym] || Config::CACHE.send(key)).to_s]
        end.reject { |_, v| v.empty? }
           .to_h

        # Sets the finished flag if appropriate
        if opts[:finished] && Config::CACHE.configured?
          data['finished'] = true
        end

        # Sets the verb
        verb = File.exists?(Config::PATH) ? 'Updated' : 'Created'

        # Writes the config
        FileUtils.mkdir_p File.dirname(FlightAsset::Config::PATH)
        File.write Config::PATH, <<~CONF
          #{Config::COMMENT_BLOCK}

          #{YAML.dump(data)}
        CONF

        # Notifies the user
        #
        $stderr.puts "#{verb} Config: #{Config::PATH}"

        $stderr.puts <<~WARN unless Config.read(Config::PATH).configured?
          The application does not appear to be fully configured!
        WARN
      end
    end
  end
end
