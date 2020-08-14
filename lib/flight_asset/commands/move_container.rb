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

      # Error if their are missing coordinates
      before(unless: :valid_method_signature?) do
        metas = ['X_START',  'X_END', 'Y_START', 'Y_END']
        (args.length - 2).times { metas.shift }
        raise InputError, <<~ERROR
          Insufficient inputs to move the container! Please try again with all the cooridinates set:
          #{Paint["#{Config::CACHE.app_name} #{args.join(' ')} #{metas.join(' ')}", :yellow]}
        ERROR
      end

      def valid_method_signature?
        case args.length
        when 1, 6
          true
        when 2
          args[1] == ''
        else
          false
        end
      end

      def parent_name
        (args.length > 2 && args[1] != '') ? args[1] : nil
      end

      def request_parent_input
        request_asset_containers_record_by_name(name)
      end

      def run
        @asset_containers_record ||= begin
          g = request_asset_containers_record_by_name(name)
          updates = {}
          if parent_name
            updates[:x_start_position] = updates[:xStartPosition] = args[2]
            updates[:x_end_position] = updates[:xEndPosition] = args[3]
            updates[:y_start_position] = updates[:yStartPosition] = args[4]
            updates[:y_end_position] = updates[:yEndPosition] = args[5]
            updates[:parent_container] = updates[:parentContainer] = request_parent_input
          else
            updates[:x_start_position] = updates[:xStartPosition] = nil
            updates[:y_start_position] = updates[:yStartPosition] = nil
            updates[:x_end_position] = updates[:xEndPosition] = nil
            updates[:y_end_position] = updates[:yEndPosition] = nil
            updates[:parent_container] = updates[:parentContainer] = NilRecord
          end
          g.update(**updates)
        end
      end
    end
  end
end
