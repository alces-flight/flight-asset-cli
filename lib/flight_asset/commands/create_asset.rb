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
    class CreateAsset < FlightAsset::Command
      include Concerns::HasInfo
      include Concerns::HasAssetsRecord

      define_args :name
      attr_accessor :assets_record

      def run
        existing = request_assets_record_by_name(name, error: false)
        raise InputError, <<~ERROR.chomp if existing
          Can not create asset '#{name}' as it already exists!
        ERROR

        self.assets_record = create_record
      end

      def asset_groups_record
        @asset_groups_record ||= request_asset_groups_record_by_name(opts.group)
      end

      def create_record
        relationships = {
          component: build_components_record
        }.tap do |r|
          if opts.group
            r[:assetGroup] = asset_groups_record,
            r[:asset_group] = asset_groups_record
          end
        end

        AssetsRecord.create(
          connection: connection,
          relationships: relationships,
          attributes: {
            name: name,
            info: info || '',
            support_type: opts.support_type,
            supportType: opts.support_type
          }
        )
      end
    end
  end
end
