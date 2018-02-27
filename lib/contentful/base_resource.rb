# frozen_string_literal: true

require_relative 'support'

module Contentful
  # Base definition of a Contentful Resource containing Sys properties
  class BaseResource
    SYS_FIELDS      = %w{ type id space contentType revision createdAt
                          updatedAt locale }.freeze
    SYS_LINK_FIELDS = %w(space contentType).freeze
    SYS_DATE_FIELDS = %w(createdAt updatedAt deletedAt).freeze

    attr_reader :raw, :default_locale

    def initialize(item, configuration = {}, _localized = false, _includes = [], depth = 0)
      @raw = item
      @default_locale = configuration[:default_locale]
      @depth = depth
      @configuration = configuration
    end

    SYS_FIELDS.each do |field_name|
      attr  = Support.snakify(field_name)
      inner = %Q{raw.fetch("sys", {})["#{field_name}"]}
      fetch = case field_name
              when *SYS_DATE_FIELDS
                "DateTime.parse(#{fetch})"
              when *SYS_LINK_FIELDS
                "build_link(#{inner})"
              else
                inner
              end

      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{attr}
          @#{attr} ||= #{fetch}
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

    # @private
    def marshal_dump
      {
        configuration: @configuration,
        raw: raw
      }
    end

    # @private
    def marshal_load(raw_object)
      @raw = raw_object[:raw]
      @configuration = raw_object[:configuration]
      @default_locale = @configuration[:default_locale]
      @depth = 0
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
      locale || default_locale
    end

    def build_link(item)
      ::Contentful::Link.new(item)
    end
  end
end
