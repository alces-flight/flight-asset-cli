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
    class RenameAsset < FlightAsset::Command
      include Concerns::HasAssetsRecord
      include Concerns::BeforeConfiguredCheck

      define_args :old_name, :new_name
      attr_reader :assets_record

      def run
        # Checks the new name isn't already taken
        # NOTE: This isn't a hard guarantee that a duplicate entry will be
        #       created as it creates a race condition. A hard guarantee can
        #       only be enforced server side
        raise InputError, <<~ERROR.chomp if request_new_assets_record
          Failed to rename the asset as "#{new_name}" already exists!
        ERROR

        @assets_record ||= request_old_assets_record.update(name: new_name)
      end

      def request_old_assets_record
        request_assets_record_by_name(old_name, error: true)
      end

      def request_new_assets_record
        request_assets_record_by_name(new_name, error: false)
      end
    end
  end
end
