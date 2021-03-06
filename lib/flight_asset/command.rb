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
  class Command
    include ActiveSupport::Callbacks

    define_callbacks :run

    CALLBACK_FILTER_TYPES.each do |type|
      define_singleton_method(type) do |**opts, &block|
        do_block = opts.delete(:do)
        set_callback(:run, type, **opts, &(do_block || block))
      end
    end

    attr_reader :args, :opts

    def self.define_args(*names)
      names.each_with_index do |name, index|
        define_method(name) { args[index] }
      end
    end

    ##
    # TODO: Remove completely
    def self.rotate_table(fetch = nil)
    end

    def initialize(*args, **opts)
      @args = args.dup
      @opts = Hashie::Mash.new(**opts.dup)
    end

    ##
    # Runs the man 'run' method with the callbacks
    #
    def run!
      Config::CACHE.logger.info "Running: #{self.class}"
      run_callbacks(:run) { run }
      Config::CACHE.logger.info 'Exited: 0'
    rescue => e
      if e.respond_to? :exit_code
        Config::CACHE.logger.fatal "Exited: #{e.exit_code}"
      else
        Config::CACHE.logger.fatal 'Exited non-zero'
      end
      Config::CACHE.logger.debug e.backtrace.reverse.join("\n")
      Config::CACHE.logger.error "(#{e.class}) #{e.message}"
      case e
      when SimpleJSONAPIClient::Errors::APIError
        raise InternalError, <<~ERROR.chomp
          The API responded with an unexpected error, see logs for details:
          #{Paint[Config::CACHE.log_path_or_stderr, :yellow]}
        ERROR
      when Faraday::Error
        raise InternalError, <<~ERROR.chomp
          Unable to connect to the API server, see logs for details:
          #{Paint[Config::CACHE.log_path_or_stderr, :yellow]}
        ERROR
      else
        raise e
      end
    end

    ##
    # The main runner method that preforms the action
    # NOTE: This method must not print to StandardOut
    #       Printing to stdout should be controlled with callbacks
    def run
    end

    ##
    # Creates a prompt object for interactive commands
    def prompt
      @prompt ||= TTY::Prompt.new
    end

    ##
    # Checks if standard out is going to a TTY
    #
    def tty?
      $stdout.tty?
    end

    ##
    # Method that returns '(none)' instead of nil when connect
    # to as tty. This is used extensively when printing
    def tty_none_or_nil
      tty? ? '(none)' : nil
    end

    ##
    # Run in verbose mode when non-interactive or with --verbose
    #
    def verbose?
      opts.verbose || !tty?
    end

    ##
    # Renders an element against a set of transform functions and
    # generates the formatted output
    def render_element(element, transforms)
      # Converts procs to prettified data
      data = transforms.map do |key, proc|
        header = Paint[key + ':', '#2794d8']
        value = Paint[proc.call(element), :green]
        [header, value]
      end

      # Determines the maximum width header for padding
      max = data.max { |(h1, _v1), (h2, _v2)| h1.length <=> h2.length }[0].length

      # Renders the data into a padded string
      combined = data.reduce('') do |memo, (header, value)|
        memo << "#{' ' * (max - header.length)}#{header} #{value}\n"
      end

      # Removes the trailing endline charcter
      combined[0..-2]
    end

    ##
    # Caches the credentials object
    def credentials
      @credentials ||= Config::CACHE.load_credentials
    end

    ##
    # Faraday Connection To the remote service
    def connection
      credentials.connection
    end

    def build_components_record
      ComponentsRecord.new(id: Config::CACHE.component_id!, connection: nil)
    end

    def request_assets_records(**opts)
      url = "components/#{Config::CACHE.component_id!}/assets"
      AssetsRecord.index_enum(connection: connection, url: url, **opts)
    end

    def request_assets_records_by_asset_group(asset_group_record, **opts)
      url = asset_group_record.assets_relationship_url
      AssetsRecord.index_enum(connection: connection, url: url, **opts)
    end

    def request_assets_record_by_name(name, error: true)
      assets = AssetsRecord.fetch_all(
        connection: connection,
        filter_opts: { name: name, component_id: Config::CACHE.component_id },
      )
      if error && assets.empty?
        raise AssetMissing, <<~ERROR.chomp
          Could not locate asset: #{name}
        ERROR
      elsif assets.length > 1
        # NOTE: This error is unrecoverable and can not be skipped
        raise DuplicateError, <<~ERROR.chomp
          Found multiple copies of asset: #{name}
          Contact your system administrator for further assistance
        ERROR
      elsif assets.length == 1
        assets.first
      else
        nil
      end
    end

    def request_asset_groups_records
      AssetGroupsRecord.index_enum(
        connection: connection,
        url: "components/#{Config::CACHE.component_id!}/asset_groups",
        includes: ['assetGroupCategroy', 'asset_group_category'],
        page_opts: { 'size' => Config::CACHE.page_size },
      )
    end

    def request_asset_groups_records_by_category(category)
      url = category.asset_groups_relationship_url
      AssetGroupsRecord.index_enum(connection: connection, url: url)
    end

    def request_asset_groups_record_by_name(name, error: true)
      groups = request_asset_groups_records.select { |a| a.name == name }
      if error && groups.empty?
        raise GroupMissing, <<~ERROR.chomp
          Could not locate group: #{name}
        ERROR
      elsif groups.length > 1
        # NOTE: This error is unrecoverable and can not be skipped
        raise DuplicateError, <<~ERROR.chomp
          Found multiple copies of group: #{name}
          Contact your system administrator for further assistance
        ERROR
      elsif groups.length == 1
        groups.first
      else
        nil
      end
    end

    def request_categories_records
      CategoriesRecord.index_enum(connection: connection)
    end

    def request_categories_record_by_name(name, error: true, **opts)
      categories = CategoriesRecord.fetch_all(
        connection: connection,
        filter_opts: { name: name },
        **opts
      )
      if error && categories.empty?
        raise CategoryMissing, <<~ERROR.chomp
          Could not locate category: #{name}
        ERROR
      elsif categories.length > 1
        # NOTE: This error is unrecoverable and can not be skipped
        raise DuplicateError, <<~ERROR.chomp
          Found multiple category: #{name}
          Contact your system administrator for further assistance
        ERROR
      elsif categories.length == 1
        categories.first
      else
        nil
      end
    end

    def request_asset_containers_records
      AssetContainersRecord.index_enum(connection: connection)
    end

    def request_asset_containers_record_by_name(name, error: true, verbose: false)
      containers = request_asset_containers_records.select { |a| a.name == name }
      if error && containers.empty?
        raise ContainerMissing, <<~ERROR.chomp
          Could not locate container: #{name}
        ERROR
      elsif containers.length > 1
        # NOTE: This error is unrecoverable and can not be skipped
        raise DuplicateError, <<~ERROR.chomp
          Found multiple copies of container: #{name}
          Contact your system administrator for further assistance
        ERROR
      elsif containers.length == 1
        id = containers.first.id
        if verbose
          AssetContainersRecord.fetch(connection: connection,
                                      url_opts: { id: id },
                                      includes: ['assets', 'parent', 'child_containers'])
        else
          AssetContainersRecord.fetch(connection: connection, url_opts: { id: id })
        end
      else
        nil
      end
    end
  end
end
