#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
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
    class MoveContainer < FlightAsset::Command
      include Concerns::HasAssetContainersRecord
      include Concerns::BeforeConfiguredCheck

      define_args :name
      attr_reader :asset_containers_record

      def parent_container
        @parent_container ||= request_asset_containers_record_by_name(args[1])
      end

      def run
        @asset_containers_record ||= begin
          g = request_asset_containers_record_by_name(name)
          updates = {
            x_start_position: args[2],
            xStartPosition: args[2],
            x_end_position: args[3],
            xEndPosition: args[3],
            y_start_position: args[4],
            yStartPosition: args[4],
            y_end_position: args[5],
            yEndPosition: args[5],
            parent_container: parent_container,
            parentContainer: parent_container
          }
          g.update(**updates)
        end
      end
    end
  end
end
