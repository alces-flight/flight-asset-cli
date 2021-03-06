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
    class ListAssets < FlightAsset::Command
      include Concerns::HasTableElements
      include Concerns::HasDecommissionedField
      include Concerns::BeforeConfiguredCheck

      def table_elements
        @table_elements ||= begin
          assets = fetch_assets.sort_by(&:name)
          if opts.only_decommissioned
            assets.select(&:decommissioned)
          elsif opts.include_decommissioned
            assets
          else
            assets.reject(&:decommissioned)
          end
        end
      end

      def fetch_assets
        if ['', true].include? opts.group
          request_assets_records(**req_opts).reject(&:asset_group_or_missing)
        elsif opts.group
          ag = request_asset_groups_record_by_name(opts.group)
          request_assets_records_by_asset_group(ag, **req_opts)
        else
          request_assets_records(**req_opts)
        end.sort_by(&:name)
      end

      def req_opts
        {
          field_opts: {
            assets: ['name', 'support_type', 'decommissioned', 'asset_group'].join(','),
          },
          includes: ['asset_group'],
          page_opts: { 'size' => Config::CACHE.page_size },
        }
      end

      def table_procs
        [
          ['Name', ->(a) { a.name }],
          ['Support Type', ->(a) {
            a.support_type.tap do |s|
              distinguish = Config::CACHE.distinguish_inherited_support_type? &&
                tty?
              if distinguish && a.support_type_inherited
                s << " (inherited)"
              end
            end
          }],
          ['Asset Group', ->(a) do
            a.asset_group_name || tty_none_or_nil
          end]
        ].tap do |t|
          if tty?
            append_group_unix_name(t)
            append_decommissioned(t)
          else
            append_decommissioned(t)
            append_group_unix_name(t)
          end
          t << ['ID', ->(a) { a.id }] if verbose?
        end
      end

      def append_group_unix_name(array)
        array << ['Group Genders Name', ->(a) do
          a.asset_group_or_missing&.unix_name || tty_none_or_nil
        end]
      end
    end
  end
end
