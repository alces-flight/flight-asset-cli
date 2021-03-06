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
  ##
  # A dummy record use to represent a relationship to nothing (aka nil)
  # The key difference being it is "truthy". This tricks SimpleJSONAPIClient
  # into rendering a nil/none as a relationship link instead of skipping it
  NilRecord = SimpleDelegator.new(nil)
  NilRecord.instance_exec do
    define_singleton_method(:to_relationship) { self }
  end

  class BaseRecord < SimpleJSONAPIClient::Base
    # Defines a method to index a particular URL, very few protections are in
    # place. However it should page responses correctly
    def self.index_enum(**base_opts)
      Enumerator.new do |yielder|
        nxt = ''
        known = {}

        # Pages the subsequent requests
        while nxt do
          # Extracts the opts from the next request
          #
          # HACK: BUG IN PAGING RESULTS
          # The API links sometimes returns nxt links like the following.
          # Note how there are two sets of query parameters:
          # https://example.com/api/v1/components/3/assets?page%5Bnumber%5D=3&page%5Bsize%5D=10?page%5Bnumber%5D=2&page%5Bsize%5D=10
          #
          # The first set of query parameters are from the request and can
          # be considered junk. The last set are the actual `page[number]`
          # and `page[size]` for the next request. The next URL must be
          # reformed otherwise all sorts of erroneous requests could be made
          nxt_params = CGI.parse(nxt.split('?').last || '')
          new_opts = ['size', 'number'].map do |key|
            [key, nxt_params.fetch("page[#{key}]", []).first]
          end.reject { |_, v| v.nil? }.to_h
          page_opts = ( base_opts[:page_opts] || {} ).merge(new_opts)
          opts = base_opts.merge(page_opts: page_opts)

          # Makes the next request
          res = operation(:fetch_all_request, :plural, **opts)

          # Extracts the required links
          slf, nxt = ['self', 'next'].map do |key|
            (res['links'] || {}).fetch(key, nil)
          end

          # Registers the response as known and errors on duplicates
          raise InternalError, <<~ERROR.chomp if known[slf]
            Caught in request loop for: #{slf}
          ERROR
          known[slf] = true

          # Register the records on the enumerator
          res['data'].each { |d| yielder << d }
        end
      end
    end

    def self.fetch_all_request(connection:,
                               url_opts: {},
                               url: self::COLLECTION_URL % url_opts,
                               filter_opts: {},
                               field_opts: [],
                               page_opts: {},
                               includes: [])
      params = {}
      params[:include] = includes.join(',') unless includes.empty?
      params[:filter] = filter_opts unless filter_opts.empty?
      params[:page] = page_opts unless page_opts.empty?
      params[:fields] = field_opts unless field_opts.empty?
      connection.get(url, params)
    end

    def meta
      @meta ||= loaded_record.has_meta? ? loaded_record.meta : {}
    end

    def has_meta?
      !@meta.nil?
    end
  end

  class AutoRecord < BaseRecord
    def self.inherited(klass)
      base = klass.name.split('::').last.chomp('Record')
      camal = base.dup.tap { |b| b[0] = b[0].downcase }
      snake = base.split(/(?=[A-Z])/).map(&:downcase).join('-')
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

    ##
    # Defines attribute getters and setters that work with both snake_case
    # and camalCase. This is to allow the API to change without affecting
    # the client
    #
    def self.fallback_meta(*attrs)
      attrs.each do |snake|
        camal = snake_to_camal(snake)
        snake = snake.to_sym

        # Define the fallback getter
        define_method(snake) do
          camal_attr = meta[camal]
          snake_attr = meta[snake]
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
          meta[snake] = value
          meta[camal] = value
        end
      end
    end
  end

  class ComponentsRecord < AutoRecord
    attributes :name

    has_many :assets, class_name: 'FlightAsset::AssetsRecord'
  end

  class AssetsRecord < AutoRecord
    fallback_attributes :name, :support_type, :info, :created_at, :updated_at,
                        :decommissioned

    fallback_meta :support_type_inherited

    attributes :x_start_position, :xStartPosition, :x_end_position, :xEndPosition,
               :y_start_position, :yStartPosition, :y_end_position, :yEndPosition

    has_one :component, class_name: 'FlightAsset::ComponentsRecord'
    has_one :asset_group, class_name: 'FlightAsset::AssetGroupsRecord'
    has_one :assetGroup, class_name: 'FlightAsset::AssetGroupsRecord'
    has_one :parentContainer, class: 'FlightAsset::AssetContainersRecord'
    has_one :parent_container, class: 'FlightAsset::AssetContainersRecord'

    def asset_group_or_missing
      key = ['asset_group', 'assetGroup'].find do |key|
        input_relationships[key]&.[]('data')
      end
      key ? send(key) : nil
    end

    def asset_group_relationship_url
      urls = ['asset_group', 'assetGroup'].map do |key|
        next unless input_relationships.key? key
        input_relationships[key]['links']['self']
      end.reject(&:nil?).uniq
      raise InternalError, <<~ERROR.chomp unless urls.length == 1
        Failed to determine asset_group relationship URL
      ERROR
      urls.first
    end

    def asset_group_name
      asset_group_or_missing&.name
    end
  end

  class AssetGroupsRecord < AutoRecord
    fallback_attributes :name, :decommissioned, :unix_name

    has_one :component, class_name: 'FlightAsset::ComponentsRecord'
    has_many :assets, class_name: 'FlightAsset::AssetsRecord'
    has_one :asset_group_category, class_name: 'FlightAsset::CategoriesRecord'
    has_one :assetGroupCategory, class_name: 'FlightAsset::CategoriesRecord'

    def assets_relationship_url
      input_relationships['assets']['links']['self']
    end

    def category_or_missing
      key = ['asset_group_category', 'assetGroupCategory'].find do |key|
        input_relationships[key]&.[]('data')
      end
      key ? send(key) : nil
    end

    def category_relationship_url
      urls = ['asset_group_category', 'assetGroupCategory'].map do |key|
        next unless input_relationships.key? key
        input_relationships[key]['links']['self']
      end.reject(&:nil?).uniq
      raise InternalError, <<~ERROR.chomp unless urls.length == 1
        Failed to determine category relationship URL
      ERROR
      urls.first
    end

    def category_name
      category_or_missing&.name
    end
  end

  class CategoriesRecord < BaseRecord
    TYPE = 'assetGroupCategories'
    COLLECTION_URL = 'asset-group-categories'
    INDIVIDUAL_URL = 'asset-group-categories/%{id}'

    attributes :name

    has_many :assetGroups, class_name: 'FlightAsset::AssetGroupsRecord'

    def asset_groups_relationship_url
      urls = ['asset_groups', 'assetGroups'].map do |key|
        next unless input_relationships.key? key
        input_relationships[key]['links']['self']
      end.reject(&:nil?).uniq
      raise InternalError, <<~ERROR.chomp unless urls.length == 1
        Failed to determine asset_groups relationship URL
      ERROR
      urls.first
    end
  end

  class AssetContainersRecord < AutoRecord
    has_one :parentContainer, class: self.to_s
    has_one :parent_container, class: self.to_s

    has_many :childContainers, class:  self.to_s
    has_many :assets, class: 'FlightAsset::AssetsRecord'

    attributes :name, :xCapacity, :yCapacity, :containerType, :container_type, :x_capacity, :y_capacity,
      :x_start_position, :xStartPosition, :x_end_position, :xEndPosition,
      :y_start_position, :yStartPosition, :y_end_position, :yEndPosition
  end
end
