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
    module Concerns
      module HasAssetsRecord
        def self.included(base)
          base.rotate_table
        end

        def table_procs
          [
            ['Name', ->(a) { a.name }],
            ['Support Type', ->(a) { a.support_type }],
            ['Decommissioned', ->(a) { a.decommissioned }],
            ['Component', ->(a) { a.component.name } ],
            ['Asset Group', ->(a) { a.asset_group_or_missing&.name }],
            ['Additional Information', ->(a) { a.info }]
          ]
        end

        def pretty_table
          parse_header_table([assets_record], table_procs)
        end

        def machine_table
          parse_table([assets_record], table_procs.map { |p| p[1] })
        end
      end
    end
  end
end

