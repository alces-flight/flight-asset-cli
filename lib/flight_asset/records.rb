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
  class AutoRecord < SimpleJSONAPIClient::Base
    def self.inherited(klass)
      klass.const_set('TYPE', klass.name.split('::').last.chomp('Record').downcase)
      klass.const_set('COLLECTION_URL', "/#{klass::TYPE}")
      klass.const_set('INDIVIDUAL_URL', "/#{klass::TYPE}/%{id}")
    end

    ##
    # Defines attribute getters and setters that work with both snake_case
    # and camalCase. This is to allow the API to change without affecting
    # the client
    #
    def self.fallback_attributes(*attrs)
      attrs.each do |snake|
        camal = snake.to_s.split('_').each_with_index.map do |part, idx|
          idx == 0 ? part : part.capitalize
        end.join.to_sym
        snake = snake.to_sym
        define_method(snake) do
          camal_attr = attributes[camal]
          snake_attr = attributes[snake]
          if camal_attr == snake_attr
            snake_attr
          elsif camal_attr.nil? || snake_attr.nil?
            snake_attr.nil? ? camal_attr : snake_attr
          else
            raise InternalError, 'Invalid API response!'
          end
        end

        define_method("#{snake}=") do |value|
          attributes[snake] = value
          attributes[camal] = value
        end
      end
    end
  end

  class ComponentsRecord < AutoRecord
    has_many :assets, class_name: 'AssetsRecord'
  end

  class AssetsRecord < AutoRecord
    def self.fetch_all_in_component(component_id:, **opts)
      fetch_all(url: "components/#{component_id}/assets", **opts)
    end

    fallback_attributes :name, :support_type, :info, :created_at, :updated_at,
                        :decommissioned

    has_one :component, class_name: 'ComponentsRecord'
  end
end

