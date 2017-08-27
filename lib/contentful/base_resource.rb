# frozen_string_literal: true

require_relative 'support'

module Contentful
  # Base definition of a Contentful Resource containing Sys properties
  class BaseResource
    SYS_FIELDS      = %w{ type id space content_type revision created_at
                          updated_at locale }.freeze
    SYS_LINK_FIELDS = %w(space contentType).freeze
    SYS_DATE_FIELDS = %w(createdAt updatedAt deletedAt).freeze

    attr_reader :raw, :default_locale, :sys

    def initialize(item, configuration = {}, _localized = false, _includes = [], depth = 0)
      @raw = item
      @default_locale = configuration[:default_locale]
      @depth = depth
      @sys = hydrate_sys
      @configuration = configuration
    end

    SYS_FIELDS.each do |camel_cased_attr|
      attr = Support.snakify(camel_cased_attr).to_sym

      define_method(attr) do
        @sys[attr]
      end
    end

    # @private
    def inspect
      "<#{repr_name} id='#{sys[:id]}'>"
    end

    # Definition of equality
    def ==(other)
      self.class == other.class && sys[:id] == other.sys[:id]
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
      @sys = hydrate_sys
      @depth = 0
      define_sys_methods!
    end

    # Issues the request that was made to fetch this response again.
    # Only works for Entry, Asset, ContentType and Space
    def reload(client = nil)
      return client.send(Support.snakify(self.class.name.split('::').last), id) unless client.nil?

      false
    end

    private

    def hydrate_sys
      result = {}
      raw.fetch('sys', {}).each do |k, v|
        if SYS_LINK_FIELDS.include?(k)
          v = build_link(v)
        elsif SYS_DATE_FIELDS.include?(k)
          v = DateTime.parse(v)
        end
        result[Support.snakify(k).to_sym] = v
      end
      result
    end

    protected

    def repr_name
      self.class
    end

    def internal_resource_locale
      sys.fetch(:locale, nil) || default_locale
    end

    def build_link(item)
      ::Contentful::Link.new(item)
    end
  end
end
