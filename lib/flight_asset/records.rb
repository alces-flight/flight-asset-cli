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
      base = klass.name.split('::').last.chomp('Record')
      camal = base.dup.tap { |b| b[0] = b[0].downcase }
      snake = base.split(/(?=[A-Z])/).map(&:downcase).join('_')
      klass.const_set('TYPE', camal)
      klass.const_set('COLLECTION_URL', "#{snake}")
      klass.const_set('INDIVIDUAL_URL', "#{snake}/%{id}")
    end

    def self.snake_to_camal(snake)
      snake.to_s.split('_').each_with_index.map do |part, idx|
        idx == 0 ? part : part.capitalize
      end.join.to_sym
    end

    ##
    # Defines attribute getters and setters that work with both snake_case
    # and camalCase. This is to allow the API to change without affecting
    # the client
    #
    def self.fallback_attributes(*attrs)
      attrs.each do |snake|
        camal = snake_to_camal(snake)
        snake = snake.to_sym

        # Define the fallback getter
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

        # Define the fallback setter
        define_method("#{snake}=") do |value|
          attributes[snake] = value
          attributes[camal] = value
        end

        # Define the keys as an internal attribute
        _attributes[snake] = true
        _attributes[camal] = true
      end
    end

    def self.fallback_has_one(snake, opts)
      has_one(snake, opts)
      camal = snake_to_camal(snake)
      relationships[camal.to_sym] = relationships[snake.to_sym]
    end
  end

  class ComponentsRecord < AutoRecord
    has_many :assets, class_name: 'FlightAsset::AssetsRecord'
  end

  class AssetsRecord < AutoRecord
    fallback_attributes :name, :support_type, :info, :created_at, :updated_at,
                        :decommissioned

    has_one :component, class_name: 'FlightAsset::ComponentsRecord'
    fallback_has_one :asset_group, class_name: 'FlightAsset::AssetGroupsRecord'

    def asset_group
      send(:assetGroup)
    end
  end

  class AssetGroupsRecord < AutoRecord
    fallback_attributes :name

    has_one :component, class_name: 'FlightAsset::ComponentsRecord'
    has_many :assets, class_name: 'FlightAsset::AssetsRecord'
  end
end

