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
    module Concerns
      module HasAssetContainersRecord
        extend ActiveSupport::Concern
        included do
          after(if: :tty?) do
            procs = (verbose? ? verbose_container_procs : simplified_container_procs)
            puts render_element(asset_containers_record, procs)

            if (children = load_children).any?
              puts
              puts Paint['Contains the following:', '#2794d8']

              child_procs = (verbose? ? verbose_child_procs : simplified_child_procs)
              children.each do |child|
                puts
                puts render_element(child, child_procs)
              end
            else
              puts
              puts Paint['The container is empty!', :red]
            end
          end

          after(unless: :tty?) do
            puts verbose_container_procs.map { |p| p[1].call(asset_containers_record) }.join("\t")
            load_children.each do |child|
              puts verbose_child_procs.map { |p| p[1].call(child) }.join("\t")
            end
          end
        end

        def load_children
          [
            *asset_containers_record.childContainers.to_a,
            *asset_containers_record.assets.to_a
          ].sort do |first, second|
            y_comp = (first.yStartPosition <=> second.yStartPosition)
            if y_comp == 0
              first.xStartPosition <=> second.xStartPosition
            else
              y_comp
            end
          end
        end

        ##
        # The container procs which appear in all outputs
        def base_container_procs
          [
            ['Name', ->(a) { a.name }],
            ['X Capacity', ->(a) { a.xCapacity } || tty_none_or_nil],
            ['Y Capacity', ->(a) { a.yCapacity || tty_none_or_nil }],
            ['Parent Container', ->(a) { ((p = a.parentContainer).nil? ? nil : p.name ) || tty_none_or_nil }]
          ]
        end

        ##
        # The container procs for the simplified TTY output
        def simplified_container_procs
          [
            *base_container_procs,
            *xy_coordinate_procs
          ]
        end

        ##
        # The container procs for non-tty outputs
        def verbose_container_procs
          [
            *base_container_procs,
            *verbose_xy_coordinate_procs
          ]
        end

        ##
        # These procs render the verbose child outputs
        def verbose_child_procs
          [
            ['Name', ->(a) { a.name }],
            ['(placeholder)', ->(_) { '' }],
            ['(placeholder)', ->(_) { '' }],
            ['Type', ->(a) { a.is_a?(AssetsRecord) ? 'asset' : 'container' }],
            *verbose_xy_coordinate_procs
          ]
        end

        ##
        # These proocs render the simplified child output
        def simplified_child_procs
          [
            ['Name', ->(a) { a.name }],
            ['Type', ->(a) { a.is_a?(AssetsRecord) ? 'asset' : 'container' }],
            *xy_coordinate_procs
          ]
        end

        def xy_coordinate_procs
          [
            ['X Position', ->(a) do
              return tty_none_or_nil unless a.xStartPosition && a.xEndPosition
              "#{a.xStartPosition} - #{a.xEndPosition}"
            end],
            ['Y Position', ->(a) do
              return tty_none_or_nil unless a.yStartPosition && a.yEndPosition
              "#{a.yStartPosition} - #{a.yEndPosition}"
            end]
          ]
        end

        def verbose_xy_coordinate_procs
          [
            ['X Start Position', ->(a) { a.xStartPosition || tty_none_or_nil }],
            ['X End Position', ->(a) { a.xEndPosition || tty_none_or_nil }],
            ['Y Start Position', ->(a) { a.yStartPosition || tty_none_or_nil }],
            ['Y End Position', ->(a) { a.yEndPosition || tty_none_or_nil }]
          ]
        end
      end
    end
  end
end
