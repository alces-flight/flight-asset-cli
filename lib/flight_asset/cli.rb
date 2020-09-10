#==============================================================================]
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
require_relative 'errors'

module FlightAsset
  class CLI
    extend Commander::CLI

    def self.create_command(name, args_str = '')
      command(name) do |c|
        c.syntax = "#{program :name} #{name} #{args_str}"
        c.hidden = true if name.split.length > 1

        c.action do |args, opts|
          require_relative '../flight_asset'
          Commands.build(name, *args, **opts.to_h).run!
        end

        yield c if block_given?
      end
    end

    program :application, 'Flight Asset'
    program :name, Config::CACHE.app_name!
    program :version, "v#{FlightAsset::VERSION}"
    program :description, 'Manage Alces Flight Center Assets'
    program :help_paging, false

    create_command 'configure' do |c|
      c.summary = 'Configure the application'
      c.slop.string '--jwt', "Update the API access token. Unset with empty string: ''"
      c.slop.string '--component-id', "Update the component by its ID. Unset with empty string ''"
    end

    global_slop.bool '--verbose', <<~DESC.chomp
      Display the full details when used in an interactive terminal.
      Non-interactive terminals follow the same output layouts and are always verbose.
    DESC

    INFO_FLAG = ->(c) do
      c.slop.string '--info',
        'Update the information. Prefix with "@" to specify a file path'
    end

    DECOMMISSION_FILTER = ->(c, plurals: 'records') do
      c.option  '--include-decommissioned',
                "Include #{plurals} that have been decommissioned"
      c.option  '--only-decommissioned',
                "Only return #{plurals} that have been decommissioned"
    end

    NAMED_FILTER = ->(c, single: 'RECORD', plurals: 'records') do
      down = single.downcase
      c.option "--#{down} #{single}", <<~MSG.chomp
        Only return #{plurals} that are within #{single}
        Specify the empty string ('') only return #{plurals} without a #{down}
      MSG
    end

    create_command 'list-assets' do |c|
      c.summary = 'Return all the assets'
      NAMED_FILTER.call(c, single: 'GROUP', plurals: 'assets')
      DECOMMISSION_FILTER.call(c, plurals: 'assets')
    end

    create_command 'show-asset', 'ASSET' do |c|
      c.summary = 'Return the detailed description of an asset'
    end

    create_command 'create-asset', 'ASSET [GROUP]' do |c|
      types_str = Config::CACHE.support_types.join(',')

      c.summary = 'Define a new asset'
      c.slop.string '--support-type', <<~DESC.chomp, meta: 'TYPE'
        Select a support type: #{types_str}
      DESC
      INFO_FLAG.call(c)
    end

    create_command 'move-asset', 'ASSET PARENT_CONTAINER X_START X_END Y_START Y_END' do |c|
      c.summary = 'Reposition an asset within a container'
    end

    create_command 'orphan-asset', 'ASSET' do |c|
      c.summary = 'Remove an asset from its container'
    end

    create_command 'decommission-asset', 'ASSET' do |c|
      c.summary = 'Flag that an asset has been decommissioned'
    end

    create_command 'recommission-asset', 'ASSET' do |c|
      c.summary = 'Unsets the decommissioned flag on an asset'
    end

    create_command 'edit-asset', 'ASSET' do |c|
      c.summary = "Update an asset's info field via the system editor"
    end

    create_command 'update-asset', 'ASSET' do |c|
      c.summary = 'Modify the type and info for an asset'
      c.slop.string '--support-type', 'Update the support type', meta: 'TYPE'
      c.slop.string '--group', <<~DESC.chomp
        Assign the asset to a different group. Empty string will unassign the group
      DESC

      INFO_FLAG.call(c)
    end

    create_command 'list-groups' do |c|
      c.summary = 'Return all the groups'
      NAMED_FILTER.call(c, single: 'CATEGORY', plurals: 'groups')
      DECOMMISSION_FILTER.call(c, plurals: 'groups')
    end

    create_command 'show-group', 'GROUP' do |c|
      c.summary = 'Return the detailed description of a group'
    end

    create_command 'create-group', 'GROUP [CATEGORY]' do |c|
      c.summary = 'Define a new group'
      c.slop.string '--genders-name', 'Set the genders name', meta: 'NAME'
    end

    create_command 'update-group', 'GROUP' do |c|
      c.summary = 'Modify an existing group'
      c.slop.string '--genders-name', 'Update the genders name', meta: 'NAME'
      c.slop.string '--category', <<~DESC.chomp
        Assign the group to a different category. Empty string will unassign the category
      DESC
    end

    create_command 'decommission-group', 'GROUP' do |c|
      c.summary = 'Flag that a group has been decommissioned'
    end

    create_command 'recommission-group', 'GROUP' do |c|
      c.summary = 'Unsets the decommissioned flag on a group'
    end

    create_command 'list-categories' do |c|
      c.summary = 'Return all the categories'
    end

    create_command 'list-containers' do |c|
      c.summary = 'Return all the containers'
    end

    create_command 'show-container', 'CONTAINER' do |c|
      c.summary = 'Return the detailed description of a container'
    end

    create_command 'create-container', 'CONTAINER' do |c|
      c.summary = 'Define a new container'
      c.slop.string '--type', 'Specify the container type',
                    meta: Config::CACHE.container_types.join('|'),
                    default: Config::CACHE.container_types.first
      # Commander has a bug (feature?) where it strips non-integers from c.slop.integer flags
      # This is likely a integration issue between Commander and Slop
      # Regardless it leads to funky error handling
      c.slop.string '--x-capacity', 'Specify a new width', meta: 'WIDTH'
      c.slop.string '--y-capacity', 'Specify a new hieght', meta: 'HEIGHT'
    end

    create_command 'update-container', 'CONTAINER' do |c|
      c.summary = 'Modify an existing container'
      c.slop.string '--type', 'Select the type of the container'
      c.slop.integer '--x-capacity', 'Define the width', meta: 'WIDTH'
      c.slop.integer '--y-capacity', 'Define the hieght', meta: 'HEIGHT'
    end

    create_command 'delete-container', 'CONTAINER' do |c|
      c.summary = 'Permanently destroy an empty container'
    end

    create_command 'move-container', 'CONTAINER PARENT X_START X_END Y_START Y_END' do |c|
      c.summary = 'Reposition a container within another container'
    end

    create_command 'orphan-container', 'CONTAINER' do |c|
      c.summary = 'Remove a container from its parent container'
    end

    alias_regex = /-assets?\Z/
    commands.keys
            .select { |c| c.match?(alias_regex) }
            .each { |c| alias_command c.sub(alias_regex, ''), c }

    create_command 'console' if Config::CACHE.development?
  end
end
