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
    class CreateContainer < FlightAsset::Command
      include Concerns::HasAssetContainersRecord
      include Concerns::BeforeConfiguredCheck

      define_args :name
      attr_accessor :asset_containers_record

      # Ensures the "option flags" are specified
      before do
        missing = [].tap do |a|
          a << '--type TYPE'          unless opts.type
          a << '--x-capacity WIDTH'   unless opts.x_capacity
          a << '--y-capacity HEIGHT'  unless opts.y_capacity
        end.join(' ')
        raise InputError, <<~ERROR.chomp unless missing.empty?
          Can not create a container without the following flags:
          #{Paint[missing, :yellow]}
        ERROR
      end

      def run
        existing = request_asset_containers_record_by_name(name, error: false)
        raise InputError, <<~ERROR.chomp if existing
          Cannot create group '#{name}' as it already exists!
        ERROR

        self.asset_containers_record = create_record
      end

      def create_record
        AssetContainersRecord.create(
          connection: connection,
          relationships: {
            component: build_components_record
          },
          attributes: {
            name: name,
          }.tap do |a|
            if opts.type
              a[:containerType] = opts.type
              a[:container_type] = opts.type
            end
            if opts.x_capacity
              a[:xCapacity] = opts.x_capacity
              a[:x_capacity] = opts.x_capacity
            end
            if opts.y_capacity
              a[:yCapacity] = opts.y_capacity
              a[:y_capacity] = opts.y_capacity
            end
          end
        )
      end
    end
  end
end
