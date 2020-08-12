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
    class UpdateAsset < FlightAsset::Command
      include Concerns::HasInfo
      include Concerns::HasAssetsRecord
      include Concerns::BeforeConfiguredCheck

      define_args :name
      attr_reader :assets_record

      def run
        @assets_record ||= begin
          a = request_assets_record_by_name(name)
          updates = {}
          if opts.support_type
            updates[:support_type] = opts.support_type
            updates[:supportType] = opts.support_type
          end
          if i = info
            updates[:info] = i
          end
          if group = opts_asset_groups_record
            updates[:asset_group] = group
            updates[:assetGroup] = group
          end
          a.update(**updates)
        end
      end

      def opts_asset_groups_record
        return if opts.group == '' || !opts.group
        request_asset_groups_record_by_name(opts.group)
      end
    end
  end
end
