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

    program :name, 'flight-asset'
    program :version, "v#{FlightAsset::VERSION}"
    program :description, 'Manage Alces Flight Center Assets'
    program :help_paging, false

    create_command 'configure' do |c|
      c.summary = 'Configure the application'
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

    create_command 'create-asset', 'ASSET' do |c|
      types_str = Config::CACHE.support_types.join(',')

      c.summary = 'Define a new asset'
      c.slop.bool '--group', 'Add the asset to an existing group'
      c.slop.string '--support-type', <<~DESC.chomp, meta: 'TYPE'
        Select a support type: #{types_str}
      DESC

      INFO_FLAG.call(c)
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
      c.option '--support-type TYPE', 'Update the support type'
      INFO_FLAG.call(c)
    end

    create_command 'move-asset', 'ASSET' do |c|
      c.summary = 'Modify which group an asset belongs to'
      c.description = <<~DESC.chomp
By default this will unassign the asset from its group. The asset will be
reassigned to a new group if the --group flag has been provided.
DESC
      c.option '--group GROUP', 'Reassign the asset to GROUP'
    end

    create_command 'list-groups' do |c|
      c.summary = 'Return all the groups'
      NAMED_FILTER.call(c, single: 'CATEGORY', plurals: 'groups')
      DECOMMISSION_FILTER.call(c, plurals: 'groups')
    end

    create_command 'show-group', 'GROUP' do |c|
      c.summary = 'Return the detailed description of a group'
    end

    create_command 'create-group', 'GROUP' do |c|
      c.summary = 'Define a new group'
      c.option '--category CATEGORY', 'Add the group to an existing category'
    end

    create_command 'decommission-group', 'GROUP' do |c|
      c.summary = 'Flag that a group has been decommissioned'
    end

    create_command 'recommission-group', 'GROUP' do |c|
      c.summary = 'Unsets the decommissioned flag on a group'
    end

    create_command 'move-group', 'GROUP' do |c|
      c.summary = 'Modify which category a group belongs to'
      c.description = <<~DESC.chomp
By default this will unassign the group from its category. The group will be
reassigned to a new category if the --category flag has been provided.
DESC
      c.option '--category CATEGORY', 'Reassign the group to CATEGORY'
    end

    create_command 'list-categories' do |c|
      c.summary = 'Return all the categories'
    end

    alias_regex = /-assets?\Z/
    commands.keys
            .select { |c| c.match?(alias_regex) }
            .each { |c| alias_command c.sub(alias_regex, ''), c }

    create_command 'console' if Config::CACHE.development?
  end
end
