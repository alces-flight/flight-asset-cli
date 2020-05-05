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
    class CreateGroup < FlightAsset::Command
      include Concerns::HasAssetGroupsRecord

      define_args :name
      attr_accessor :asset_groups_record

      def run
        existing = request_asset_groups_record_by_name(name, error: false)
        raise InputError, <<~ERROR.chomp if existing
          Can not create group '#{name}' as it already exists!
        ERROR

        self.asset_groups_record = create_record
      end

      def categories_record
        @categories_record ||= if cat_name = opts.category
          request_categories_record_by_name(cat_name)
        end
      end

      def group_name
        opts.group || Config::CACHE.create_dummy_group_name
      end

      def create_record
        AssetGroupsRecord.create(
          connection: connection,
          relationships: relationships,
          attributes: {
            name: name
          }
        )
      end

      def relationships
        { component: build_components_record }.tap do |rels|
          if cat = categories_record
            rels[:assetGroupCategory] = cat
            rels[:asset_group_category] = cat
          end
        end
      end
    end
  end
end
