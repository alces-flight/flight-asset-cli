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
      module HasTableElement
        extend ActiveSupport::Concern

        included do
          after(if: :tty?) do
            # Local caches the element so it can be reused
            element = table_element

            # Converts procs to prettified data
            data = table_procs.map do |key, proc|
              header = Paint[key + ':', '#2794d8']
              value = Paint[proc.call(element), :green]
              [header, value]
            end

            # Determines the maximum width header for padding
            max = data.max { |h, v| h.length }[0].length

            # Prints the data with required padding
            data.each do |header, value|
              puts "#{' ' * (max - header.length)}#{header} #{value}"
            end
          end

          after(unless: :tty?) do
            element = table_element
            puts table_procs.map { |_, p| p.call(element) }.join("\t")
          end
        end

        def table_procs
          raise NotImplementedError
        end

        def table_element
          raise NotImplementedError
        end
      end
    end
  end
end
