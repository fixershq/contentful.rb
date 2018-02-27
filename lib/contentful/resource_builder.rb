# frozen_string_literal: true

require_relative 'error'
require_relative 'space'
require_relative 'content_type'
require_relative 'entry'
require_relative 'asset'
require_relative 'array'
require_relative 'link'
require_relative 'deleted_entry'
require_relative 'deleted_asset'

module Contentful
  # Transforms a Contentful::Response into a Contentful::Resource or a Contentful::Error
  # See example/resource_mapping.rb for advanced usage
  class ResourceBuilder
    attr_reader :raw, :default_locale, :endpoint, :depth, :localized,
      :resource_mapping, :entry_mapping, :resource, :includes

    def initialize(json, default_locale:, resource_mapping:, entry_mapping:,
                   includes:, localized:, depth:, endpoint: nil)

      @raw = json

      @default_locale = default_locale
      @resource_mapping = resource_mapping
      @entry_mapping = entry_mapping
      @includes = includes

      @localized = localized
      @depth = depth
      @endpoint = endpoint
    end

    # Starts the parsing process.
    #
    # @return [Contentful::Resource, Contentful::Error]
    def run
      return build_array if array?
      build_single
    rescue UnparsableResource => error
      error
    end

    private

    def build_array
      result = raw['items'].map { |item| build_item(item, fetch_includes) }

      array_class = fetch_array_class
      array_class.new(raw.dup.merge('items' => result),
                      default_locale: default_locale,
                      resource_mapping: resource_mapping,
                      entry_mapping: entry_mapping,
                      includes: includes,
                      localized: localized,
                      depth: depth,
                      endpoint: endpoint)
    end

    def build_single
      build_item(raw, includes)
    end

    def build_item(item_json, includes = [])
      buildables = %w(Entry Asset ContentType Space DeletedEntry DeletedAsset)
      item_type = buildables.detect { |b| b.to_s == item_json['sys']['type'] }
      fail UnparsableResource, 'Item type is not known, could not parse' if item_type.nil?
      item_class = resource_class(item_json)

      item_class.new(item_json,
                     default_locale: default_locale,
                     resource_mapping: resource_mapping,
                     entry_mapping: entry_mapping,
                     includes: includes,
                     localized: localized,
                     depth: depth)
    end

    def fetch_includes
      includes = []
      %w(Entry Asset).each do |type|
        if raw.fetch('includes', {}).key?(type)
          includes.concat(raw['includes'].fetch(type, []))
        end
      end
      includes
    end

    def resource_class(item)
      return fetch_custom_resource_class(item) if %w(Entry Asset).include?(item['sys']['type'])
      resource_mapping[item['sys']['type']]
    end

    def fetch_custom_resource_class(item)
      case item['sys']['type']
      when 'Entry'
        resource_class = entry_mapping[item['sys']['contentType']['sys']['id']]
        return resource_class unless resource_class.nil?

        return fetch_custom_resource_mapping(item, 'Entry', Entry)
      when 'Asset'
        return fetch_custom_resource_mapping(item, 'Asset', Asset)
      end
    end

    def fetch_custom_resource_mapping(item, type, default_class)
      resources = resource_mapping[type]
      return default_class if resources.nil?

      return resources if resources.is_a?(Class)
      return resources[item] if resources.respond_to?(:call)

      default_class
    end

    def fetch_array_class
      return SyncPage if sync?
      ::Contentful::Array
    end

    def localized?
      return true if @localized
      return true if array? && sync?
      false
    end

    def array?
      raw.fetch('sys', {}).fetch('type', '') == 'Array'
    end

    def sync?
      raw.fetch('nextSyncUrl', nil) || raw.fetch('nextPageUrl', nil)
    end
  end
end
