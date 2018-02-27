# frozen_string_literal: true

require_relative 'support'

module Contentful
  # Base definition of a Contentful Resource containing Sys properties
  class BaseResource
    SYS_FIELDS      = %w{ type id space content_type revision created_at
                          updated_at locale }.freeze
    SYS_LINK_FIELDS = %w(space contentType).freeze
    SYS_DATE_FIELDS = %w(createdAt updatedAt deletedAt).freeze

    attr_reader :default_locale, :depth, :id, :includes, :localized, :raw,
      :resource_mapping, :entry_mapping

    def initialize(json, resource_mapping:, entry_mapping:, default_locale:, localized:, includes:, depth:)
      @raw = json
      @id  = json.fetch("sys", {})["id"]

      @default_locale   = default_locale
      @depth            = depth
      @entry_mapping    = entry_mapping
      @includes         = includes
      @localized        = localized
      @resource_mapping = resource_mapping
    end

    SYS_LINK_FIELDS.each do |field_name|
      attr = Support.snakify(field_name)

      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{attr}
          @#{attr} ||= build_link(raw.fetch("sys", {})["#{field_name}"])
        end
      CODE
    end

    SYS_DATE_FIELDS.each do |field_name|
      attr = Support.snakify(field_name)

      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{attr}
          @#{attr} ||= DateTime.parse(raw.fetch("sys", {})["#{field_name}"])
        end
      CODE
    end

    # @private
    def inspect
      "<#{repr_name} id='#{id}'>"
    end

    # Definition of equality
    def ==(other)
      self.class == other.class && id == other.id
    end

    # Issues the request that was made to fetch this response again.
    # Only works for Entry, Asset, ContentType and Space
    def reload(client = nil)
      return client.send(Support.snakify(self.class.name.split('::').last), id) unless client.nil?

      false
    end

    protected

    def repr_name
      self.class
    end

    def internal_resource_locale
      raw.fetch("sys", {})["locale"] || default_locale
    end

    def build_link(json)
      ::Contentful::Link.new(json,
                             default_locale:   default_locale,
                             depth:            depth,
                             entry_mapping:    entry_mapping,
                             includes:         includes,
                             localized:        localized,
                             resource_mapping: resource_mapping)
    end
  end
end
