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

require 'commander'

require_relative 'version'

module FlightAsset
  module CLI
    extend Commander::CLI

    program :name, 'flight-asset'
    program :version, "v#{FlightAsset::VERSION}"
    program :description, 'Manage Alces Flight Center Assets'
    program :help_paging, false

    def self.create_command(name, args_str = '')
      command(name) do |c|
        c.syntax = "#{program :name} #{name} #{args_str}"
        c.hidden = true if name.split.length > 1

        c.action do |args, opts|
          require_relative '../flight_asset'
          cmd = Commands.build(name, *args, **opts.__hash__)
          cmd.run
          if $stdout.tty?
            puts cmd.pretty_table.render(:ascii)
          else
            puts cmd.machine_table.render(:basic)
          end
        end

        yield c if block_given?
      end
    end

    create_command 'list' do |c|
    end

    create_command 'show', 'ASSET_NAME' do |c|
    end
  end
end
