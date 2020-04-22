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
            puts cmd.pretty_table.render(:ascii, multiline: true)
          else
            cmd.machine_table.rows.each do |rows|
              puts rows.join("\t")
            end
          end
        end

        yield c if block_given?
      end
    end

    ##
    # NOTE: This overrides the Commander::CLI method to allow the wizard to work.
    # This should be integrated into Commander at some point
    def self.run_with_wizard(*args)
      cmds = wizard? ? { "wizard" => wizard_command } : commands
      instance = Commander::Runner.new(
        @program, cmds, default_command, global_options, aliases, args
      )
      instance.run
    rescue StandardError, Interrupt => e
      $stderr.puts e.backtrace.reverse if args.include?('--trace')
      error_handler(instance, e)
    end

    def self.wizard?
      !Config::CACHE.finished?
    end

    def self.commands_or_wizzard
      commands
    end

    def self.wizard_command(&b)
      if b
        @wizard_command = Commander::Command.new('wizard').tap do |cmd|
          b.call(cmd)
        end
      else
        @wizard_command
      end
    end

    wizard_command do |c|
      c.syntax = "#{program :name} wizard"
      c.summary = 'Set the configuration keys'
      c.option '--finished', 'Exit the configuration wizard'
      Config::REFERENCE_OPTS.each do |key, msg|
        next if key == 'finished'
        required = Config::CACHE.class.requires[key.to_sym]
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
        c.option "--#{key.gsub('_', '-')} #{ suffix }", cli_msg
        c.action do |_, opts|
          # Extracts the data
          opts = opts.__hash__
          data = Config::REFERENCE_OPTS.keys.map do |key|
            [key, (opts[key.to_sym] || Config::CACHE.send(key)).to_s]
          end.reject { |_, v| v.empty? }
             .to_h

          # Sets the finished flag if appropriate
          if opts[:finished] && Config::CACHE.configured?
            data['finished'] = true
          end

          # Writes the config
          FileUtils.mkdir_p File.dirname(FlightAsset::Config::PATH)
          File.write Config::PATH, <<~CONF
            #{Config::COMMENT_BLOCK}

            #{YAML.dump(data)}
          CONF

          new_config = Config.read(Config::PATH)

          # Notifies the user
          #
          $stderr.puts "Created Config: #{Config::PATH}"
          $stderr.puts <<~WARN if new_config.configured? && !opts[:finished]

          The application appears to be fully configured. Use the
          --finished flag to exit the wizard.
          WARN
          $stderr.puts <<~WARN if opts[:finished] && !new_config.finished?

            Ignoring the --finished flag as the application has not
            been fully configured.
          WARN
          $stderr.puts <<~WARN unless Config.read(Config::PATH).configured?

            The application does not appear to be fully configured!
            Please rerun the 'wizard --help' for the required flags
          WARN
        end
      end
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
      c.option '--info INFO', 'Additional information about the asset'
      c.option '--info-path PATH', 'Override --info with contents of a file'
    end

    create_command 'decommission-asset', 'ASSET' do |c|
      c.summary = 'Flag that an asset has been decommissioned'
    end

    create_command 'update-asset', 'ASSET' do |c|
      c.summary = 'Modify the support type for an asset'
      c.option '--support-type SUPPORT_TYPE', 'Update the support type'
    end

    create_command 'move-asset', 'ASSET' do |c|
      c.summary = 'Modify which group an asset belongs to'
      c.description = <<~DESC.chomp
        By default this will unassign the asset from its group. The asset will
        be reassigned to a new group if the --group flag has been provided.
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
        By default this will unassign the group from its category. The group
        will be reassigned to a new category if the --category flag has been
        provided.
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

    unless wizard?
      alias_regex = /-assets?\Z/
      commands.keys
              .select { |c| c.match?(alias_regex) }
              .each { |c| alias_command c.sub(alias_regex, ''), c }
    end

    if Config::CACHE.development?
      create_command 'console'
    end
  end
end
