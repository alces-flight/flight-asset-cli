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

module FlightAsset
  module Commands
    class Configure < Command
      def run
        if tty? && opts.select { |_, v| v }.empty?
          # Run interactively if connected to a TTY without options
          run_interactive
        else
          # Run non interactively
          run_non_interactive
        end
      end


      def run_interactive
        old = Config::CACHE.load_credentials
        data = CredentialsConfig.new
        data.component_id = prompt.ask  'Component Identifier:',
                                        default: old.component_id
        jwt = prompt.ask  'Alces Flight Center API token:',
                          default: masked_jwt(old.jwt)
        if jwt == masked_jwt(old.jwt)
           data.jwt = old.jwt
        else
           data.jwt = jwt
        end
        FileUtils.mkdir_p File.dirname(Config::CACHE.credentials_path)
        File.write  Config::CACHE.credentials_path,
                    YAML.dump(data.to_h)
      end

      def run_non_interactive
        data = Config::CACHE.load_credentials
        data.jwt = opts.jwt if opts.jwt
        data.component_id = opts.component_id if opts.component_id
        FileUtils.mkdir_p File.dirname(Config::CACHE.credentials_path)
        File.write  Config::CACHE.credentials_path,
                    YAML.dump(data.to_h)
      end

      def masked_jwt(jwt)
        return nil if jwt.nil?
        return ('*' * jwt.length) if jwt[-8..-1].nil?
        ('*' * 24) + jwt[-8..-1]
      end
    end
  end
end
