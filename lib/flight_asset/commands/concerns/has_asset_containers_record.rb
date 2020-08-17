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
            puts render_element(asset_containers_record, container_procs)
            unless asset_containers_record.parentContainer.nil?
              puts
              puts render_element(asset_containers_record, tty_parent_container_procs)
            end
            asset_containers_record.childContainers.each do |child|
              puts
              puts render_element(child, tty_child_container_procs)
            end
          end

          after(unless: :tty?) do
            puts container_procs.map { |p| p[1].call(asset_containers_record) }.join("\t")
            if asset_containers_record.parentContainer.nil?
              puts
            else
              puts non_tty_parent_container_procs.map { |p| p[1].call(asset_containers_record) }.join("\t")
            end
            asset_containers_record.childContainers.each do |child|
              puts non_tty_child_container_procs.map { |p| p[1].call(child) }.join("\t")
            end
          end
        end

        def container_procs
          [
            ['Name', ->(a) { a.name }],
            ['Type', ->(a) { a.containerType }],
            ['X Capacity', ->(a) { a.xCapacity }],
            ['Y Capacity', ->(a) { a.yCapacity }]
          ]
        end

        ##
        # These procs take the original container as their input as this is
        # where the start/stop positions are stored
        def tty_parent_container_procs
          [
            ['Location', ->(a) { "#{a.parentContainer.containerType} - #{a.parentContainer.name}" }],
            ['X Position', ->(a) { "#{a.xStartPosition} - #{a.xEndPosition}" }],
            ['Y Position', ->(a) { "#{a.yStartPosition} - #{a.yEndPosition}" }]
          ]
        end

        ##
        # These procs take the original container as their input as this is
        # where the start/stop positions are stored
        def non_tty_parent_container_procs
          [
            [nil, ->(a) { a.parentContainer.name }],
            [nil, ->(a) { a.parentContainer.containerType }],
            [nil, ->(a) { a.xStartPosition }],
            [nil, ->(a) { a.xEndPosition }],
            [nil, ->(a) { a.yStartPosition }],
            [nil, ->(a) { a.yEndPosition }]
          ]
        end

        ##
        # These procs take the child container record directly
        def tty_child_container_procs
          [
            ['Location', ->(a) { "#{a.containerType} - #{a.name}" }],
            ['X Position', ->(a) { "#{a.xStartPosition} - #{a.xEndPosition}" }],
            ['Y Position', ->(a) { "#{a.yStartPosition} - #{a.yEndPosition}" }]
          ]
        end

        ##
        # These procs take the child container record directly
        def non_tty_child_container_procs
          [
            [nil, ->(a) { a.name }],
            [nil, ->(a) { a.containerType }],
            [nil, ->(a) { a.xStartPosition }],
            [nil, ->(a) { a.xEndPosition }],
            [nil, ->(a) { a.yStartPosition }],
            [nil, ->(a) { a.yEndPosition }]
          ]
        end
      end
    end
  end
end
