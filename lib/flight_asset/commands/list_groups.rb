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
    class ListGroups < FlightAsset::Command
      include Concerns::HasTableElements
      include Concerns::HasDecommissionedField
      include Concerns::BeforeConfiguredCheck

      def table_elements
        @table_elements ||= begin
          groups = fetch_groups.sort_by(&:name)
          if opts.only_decommissioned
            groups.select(&:decommissioned)
          elsif opts.include_decommissioned
            groups
          else
            groups.reject(&:decommissioned)
          end
        end
      end

      def fetch_groups
        if ['', true].include?(opts.category)
          request_asset_groups_records.reject(&:category_or_missing)
        elsif opts.category
          cat = request_categories_record_by_name(opts.category)
          request_asset_groups_records_by_category(cat)
        else
          request_asset_groups_records
        end
      end

      def table_procs
        [
          ['Name', ->(a) { a.name }],
          ['Category', ->(a) do
            a.category_name || tty_none_or_nil
          end],
        ].tap do |t|
            if tty?
              append_group_unix_name(t)
              append_decommissioned(t)
            else
              append_decommissioned(t)
              append_group_unix_name(t)
            end
          end
      end

      def append_group_unix_name(array)
        array << ['Genders Name', ->(a) do
          a.unix_name || tty_none_or_nil
        end]
      end
    end
  end
end
