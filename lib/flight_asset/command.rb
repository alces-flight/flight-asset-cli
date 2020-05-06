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
      run_callbacks(:run) { run }
    rescue => e
      Config::CACHE.logger.fatal 'An error has occurred'
      Config::CACHE.logger.debug e.full_message
      raise e
    end

    ##
    # The main runner method that preforms the action
    # NOTE: This method must not print to StandardOut
    #       Printing to stdout should be controlled with callbacks
    def run
    end

    ##
    # Checks if standard out is going to a TTY
    #
    def tty?
      $stdout.tty?
    end

    ##
    # Faraday Connection To the Remote service
    def connection
      @connection ||= begin
        default_headers = {
          'Accept' => 'application/vnd.api+json',
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{Config::CACHE.jwt!}"
        }

        url = File.join(Config::CACHE.base_url!, Config::CACHE.api_prefix!)
        Faraday.new(url: url, headers: default_headers) do |c|
          c.use Faraday::Response::Logger, Config::CACHE.logger, { bodies: true } do |logger|
            logger.filter(/(Authorization:)(.*)/, '\1 [REDACTED]')
          end
          c.request :json
          c.response :json, :content_type => /\bjson$/
          c.adapter :net_http
        end
      end
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
      assets = request_assets_records.select { |a| a.name == name }
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
        includes: ['assetGroupCategroy', 'asset_group_category']
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

    def request_categories_record_by_name(name, error: true)
      categories = request_categories_records.select { |c| c.name == name }
      if error && categories.empty?
        raise CategoriesMissing, <<~ERROR.chomp
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

    def request_assets_record_move_asset_group(assets_record, asset_groups_record = nil)
      rel_url = assets_record.asset_group_relationship_url
      data = asset_groups_record&.to_relationship
      connection.patch(rel_url, { data: data })
      AssetsRecord.fetch(
        connection: connection, url_opts: { id: assets_record.id }
      )
    end

    def request_asset_groups_record_move_category(asset_groups_record, category_record = nil)
      rel_url = asset_groups_record.category_relationship_url
      data = category_record&.to_relationship
      connection.patch(rel_url, { data: data })
      AssetGroupsRecord.fetch(
        connection: connection, url_opts: { id: asset_groups_record.id }
      )
    end
  end
end

