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
    attr_reader :args, :opts

    def self.define_args(*names)
      names.each_with_index do |name, index|
        define_method(name) { args[index] }
      end
    end

    ##
    # Denotes if the table has been rotated
    def self.rotate_table(fetch = nil)
      @rotate_table = true unless fetch
      @rotate_table || false
    end

    def initialize(*args, **opts)
      @args = args.dup
      @opts = Hashie::Mash.new(**opts.dup)
    end

    ##
    # The main runner method that preforms the action
    # This method must not print to StandardOut as this gets in the way of output
    # toggling
    def run
    end

    ##
    # Table for generating the prettified output intended for humans
    # This output MAY change but should be avoided
    def pretty_table
      raise NotImplementedError
    end

    ##
    # Machine readable table for the command
    # This table MUST only be changed in machine compatible way
    # This means the following
    #   * Headers MUST not be returned
    #   * The column (/row) orders must be consistent
    #   * New columns/rows must be appended to the end
    #   * Tables MUST be TAB separated
    #   * The above can only be broken on major version bumps
    #
    # NOTE: The column order MAY differ from the pretty_output
    # method due to the above restrictions, if and when this happens
    # a --headers global flag should be added to print the headers
    def machine_table
      raise InternalError, 'No output available!'
    end

    ##
    # Faraday Connection To the Remote service
    def connection
      @connection ||= begin
        default_headers = {
          'Accept' => 'application/vnd.api+json',
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{Config::CACHE.jwt}"
        }

        Faraday.new(url: Config::CACHE.base_url, headers: default_headers) do |c|
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
      ComponentsRecord.new(id: Config::CACHE.component_id, connection: nil)
    end

    def request_assets_records
      url = "components/#{Config::CACHE.component_id}/assets"
      AssetsRecord.fetch_all(connection: connection, url: url)
    end

    def request_assets_record_by_name(name, error: true)
      request_assets_records.find { |a| a.name == name }.tap do |a|
        raise AssetMissing, <<~ERROR.chomp if a.nil? && error
          Could not locate asset: #{name}
        ERROR
      end
    end

    def request_asset_groups_records
      AssetGroupsRecord.fetch_all(
        connection: connection,
        url: "components/#{Config::CACHE.component_id}/asset_groups",
        includes: ['assetGroupCategroy', 'asset_group_category']
      )
    end

    def request_asset_groups_record_by_name(name, error: true)
      request_asset_groups_records.find { |a| a.name == name }.tap do |g|
        raise GroupMissing, <<~ERROR.chomp if g.nil? && error
          Could not locate group: #{name}
        ERROR
      end
    end

    def request_categories_records
      CategoriesRecord.fetch_all(connection: connection)
    end

    def request_categories_record_by_name(name, error: true)
      request_categories_records.find { |c| c.name == name }.tap do |c|
        raise CategoryMissing, <<~ERROR.chomp if c.nil? && error
          Could not locate category: #{name}
        ERROR
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

    # The procs should be a 2N array of headers to procs OR a hash
    def parse_header_table(elements, headers_and_procs_raw)
      headers_and_procs = headers_and_procs_raw.to_a
      headers = headers_and_procs.map { |h| h[0] }
      procs = headers_and_procs.map { |h| h[1] }
      parse_table(elements, procs, headers: headers)
    end

    def parse_table(elements, procs, headers: nil)
      rows = elements.map do |element|
        procs.map { |p| p.respond_to?(:call) ? p.call(element) : p }
      end

      # flips the table if required
      opts = if self.class.rotate_table(true)
        temp_rows = rows.dup
        temp_rows.unshift(headers) if headers
        max = temp_rows.map(&:length).max
        new_rows = (0...max).map do |idx|
          temp_rows.map { |row| row[idx] }
        end
        { rows: new_rows }
      else
        { rows: rows }.tap { |o| o[:header] = headers if headers }
      end

      TTY::Table.new(**opts)
    end
  end
end

