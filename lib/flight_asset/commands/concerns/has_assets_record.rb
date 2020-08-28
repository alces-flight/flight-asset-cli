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
    module Concerns
      module HasAssetsRecord
        extend ActiveSupport::Concern
        include HasTableElement
        include HasDecommissionedField

        def table_element
          assets_record
        end

        def table_procs
          [
            ['Name', ->(a) { a.name }],
            ['Support Type', ->(a) do
              a.support_type.tap do |s|
                distinguish = Config::CACHE.distinguish_inherited_support_type? &&
                  tty?
                if distinguish && a.support_type_inherited
                  s << " (inherited)"
                end
              end
            end],
            ['Component', ->(a) { a.component.name } ],
            ['Asset Group', ->(a) do
              a.asset_group_name || tty_none_or_nil
            end]
          ].tap do |t|
            append_decommissioned(t)

            if verbose?
              t << ['ID', ->(a) { a.id }]
              t << ['Parent Container', ->(a) do
                if a.parentContainer.nil?
                  tty_none_or_nil
                else
                  a.parentContainer.name
                end
              end]
              t << ['X Start Position', ->(a) do
                a.xStartPosition || tty_none_or_nil
              end]
              t << ['X End Position', ->(a) do
                a.xEndPosition || tty_none_or_nil
              end]
              t << ['Y Start Position', ->(a) do
                a.yStartPosition || tty_none_or_nil
              end]
              t << ['Y End Position', ->(a) do
                a.yEndPosition || tty_none_or_nil
              end]
            else
              t << ['Parent Container', ->(a) do
                if a.parentContainer.nil?
                  tty_none_or_nil
                else
                  "#{a.parentContainer.containerType} - #{a.parentContainer.name}"
                end
              end]
              t << ['X Position', ->(a) do
                if a.xStartPosition || a.xEndPosition
                  "#{a.xStartPosition} - #{a.xEndPosition}"
                else
                  tty_none_or_nil
                end
              end]
              t << ['Y Position', ->(a) do
                if a.yStartPosition || a.yEndPosition
                  "#{a.yStartPosition} - #{a.yEndPosition}"
                else
                  tty_none_or_nil
                end
              end]
            end

            t << ['Additional Information', ->(a) do
              if tty? && a.info.to_s.length > 0
                "\n" + a.info
              elsif tty?
                '(none)'
              else
                a.info
              end
            end]
          end
        end
      end
    end
  end
end

