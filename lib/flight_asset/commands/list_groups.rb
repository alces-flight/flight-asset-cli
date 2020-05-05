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

      def table_elements
        @table_elements ||= if ['', true].include?(opts.category)
          request_asset_groups_records.reject(&:category_or_missing)
        elsif opts.category
          cat = request_categories_record_by_name(opts.category)
          request_asset_groups_records_by_category(cat)
        else
          request_asset_groups_records
        end.sort_by(&:name)
      end

      def table_procs
        [
          ['Name', ->(a) { a.name }],
          ['Category', ->(a) { a.category_or_missing&.name }],
          ['Decommissioned', ->(a) { a.decommissioned }]
        ]
      end
    end
  end
end
