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
    class MoveGroup < FlightAsset::Command
      include Concerns::HasAssetGroupsRecord
      include Concerns::HasCategoryInput
      include Concerns::BeforeConfiguredCheck

      define_args :name
      attr_accessor :asset_groups_record

      before do
        category_name = args.length < 2 ? '' : args[1]
        msg = <<~WARN.chomp
          This command has been deprecated and will cease to function as expected in the
          next major release. Please use the following:
          #{Paint["#{Config::CACHE.app_name} update-group '#{name}' --category '#{category_name}'", :yellow]}
        WARN
        Config::CACHE.logger.warn msg
        $stderr.puts msg
      end

      def run
        initial = request_asset_groups_record_by_name(name)
        self.asset_groups_record = request_asset_groups_record_move_category(
          initial, request_input_categories_record_or_nil
        )
      end
    end
  end
end
