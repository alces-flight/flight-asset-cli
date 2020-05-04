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
    module Multipart
      include Commander::CLI

      module ClassMethods
        def blocks
          @blocks ||= {}
        end

        def define(name, &block)
          blocks[name.to_sym] = block
        end

        def build(*parts)
          parts.map { |k| blocks[k.to_sym] }
               .each_with_object(self.new) { |b, cli| cli.instance_exec(&b) }
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    include Multipart

    def create_command(name, args_str = '')
      command(name) do |c|
        c.syntax = "#{program :name} #{name} #{args_str}"
        c.hidden = true if name.split.length > 1

        c.action do |args, opts|
          require_relative '../flight_asset'
          Commands.build(name, *args, **opts.__hash__).run!
        end

        yield c if block_given?
      end
    end

    define :shared do
      def self.configure_command
        commands['configure'].tap { |c| yield(c) if block_given? }
      end

      program :name, 'flight-asset'
      program :version, "v#{FlightAsset::VERSION}"
      program :description, 'Manage Alces Flight Center Assets'
      program :help_paging, false

      create_command 'configure' do |c|
        c.option '--finished', 'Exit the configuration wizard'
        Config.keys.each do |key|
          msg = Config.summaries[key]
          required = Config::CACHE.class.requires[key]
          default = Config::CACHE.send(key).to_s
          default = nil if default.empty?
          cli_msg = if default
                      "#{msg}\nDEFAULT: #{default}"
                    else
                      msg
                    end
          suffix = if default || !required
                     'OPTIONAL'
                   else
                     'REQUIRED'
                   end
          c.option "--#{key.to_s.gsub('_', '-')} #{ suffix }", cli_msg
        end
      end
    end

    define :configure do
      def self.missing_help_text
        <<~HELP.chomp
The following flags are missing:
#{Config::CACHE.missing_keys.map { |k| "  --#{k.to_s.gsub('_', '-')}" }.join("\n")}
HELP
      end

      configure_command do |c|
        c.summary = 'Bootstrap the config generation and configuration'
        c.description = <<~DESC.chomp
The other commands have been disabled as the application has not been configured!

#{missing_help_text}
DESC
      end

      create_command '__missing__', '...' do |c|
        c.summary = 'Special internal missing helper'
        c.hidden = true
        c.action do |args, _|
          require_relative '../flight_asset/errors.rb'

          raise InputError, <<~ERROR.chomp
The following command can not be processed at this time:
#{program(:name)} #{args.first}

The application needs to be configured before any further commands
are enabled. Please refer to the configuration help for futher details:
#{program(:name)} configure --help

#{missing_help_text}
ERROR
        end
      end

      default_command '__missing__'
    end

    define :main do
      configure_command do |c|
        c.summary = 'Reconfigure the application'
      end

      INFO_FLAGS = ->(c) do
        c.option '--info INFO', 'Additional information about the asset'
        c.option '--info-path PATH', 'Override --info with contents of a file'
      end

      create_command 'list-assets' do |c|
        c.summary = 'Return all the assets'
        c.option '--group GROUP', 'Filter the assets by GROUP'
      end

      create_command 'show-asset', 'ASSET' do |c|
        c.summary = 'Return the detailed description of an asset'
      end

      create_command 'create-asset', 'ASSET' do |c|
        c.summary = 'Define a new asset'
        c.option '--group GROUP', 'Add the asset to an existing group'
        c.option '--support-type SUPPORT_TYPE', 'Set the support type', default: 'advice'
        INFO_FLAGS.call(c)
      end

      create_command 'decommission-asset', 'ASSET' do |c|
        c.summary = 'Flag that an asset has been decommissioned'
      end

      create_command 'edit-asset-info', 'Asset' do |c|
        c.summary = "Update an asset's info field via the system editor"
      end

      create_command 'update-asset', 'ASSET' do |c|
        c.summary = 'Modify the support type for an asset'
        c.option '--support-type SUPPORT_TYPE', 'Update the support type'
        INFO_FLAGS.call(c)
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
        c.option '--category CATEGORY', 'Filter the groups be CATEGORY'
      end

      create_command 'show-group', 'ASSET_GROUP' do |c|
        c.summary = 'Return the detailed description of a group'
      end

      create_command 'decommission-group', 'ASSET_GROUP' do |c|
        c.summary = 'Flag that a group has been decommissioned'
      end

      create_command 'move-group', 'ASSET_GROUP' do |c|
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

      create_command 'show-category', 'CATEGORY' do |c|
        c.summary = 'Return the detailed description of a category'
      end

      create_command 'set-token', 'TOKEN' do |c|
        c.summary = 'Update the API access token'
      end

      # NOTE: Disabled due to parsing bug
      # alias_regex = /-assets?\Z/
      # commands.keys
      #         .select { |c| c.match?(alias_regex) }
      #         .each { |c| alias_command c.sub(alias_regex, ''), c }

      # alias_command 'edit',       'edit-asset-info'
      # alias_command 'edit-asset', 'edit-asset-info'
    end

    define(:development) do
      create_command 'console'
    end
  end
end
