# frozen_string_literal: true

require_relative 'support'
require_relative 'base_resource'

module Contentful
  # Base definition of a Contentful Resource containing Field properties
  class FieldsResource < BaseResource
    def initialize(json, localized:, includes:, **rest)
      super

      @fields = hydrate_fields(localized, includes)
    end

    # Returns all fields of the asset
    #
    # @return [Hash] fields for Resource on selected locale
    def fields(wanted_locale = nil)
      wanted_locale = internal_resource_locale if wanted_locale.nil?
      @fields.fetch(wanted_locale.to_s, {})
    end

    # Returns all fields of the asset with locales nested by field
    #
    # @return [Hash] fields for Resource grouped by field name
    def fields_with_locales
      remapped_fields = {}
      locales.each do |locale|
        fields(locale).each do |name, value|
          remapped_fields[name] ||= {}
          remapped_fields[name][locale.to_sym] = value
        end
      end

      remapped_fields
    end

    # Provides a list of the available locales for a Resource
    def locales
      @fields.keys
    end

    def method_missing(method_name, *args, &block)
      if fields.has_key? method_name
        fields[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      fields.has_key? method_name
    end

    private

    def hydrate_fields(localized, includes)
      return {} unless raw.key?('fields')

      locale = internal_resource_locale.dup
      result = Hash.new { |h,k| h[k] = {} }

      if localized
        raw['fields'].each do |name, locales|
          locales.each do |loc, value|
            result[loc][Support.snakify(name).to_sym] = coerce(
              Support.snakify(name),
              value,
              localized,
              includes
            )
          end
        end
      else
        raw['fields'].each do |name, value|
          result[locale][Support.snakify(name).to_sym] = coerce(
            Support.snakify(name),
            value,
            localized,
            includes
          )
        end
      end

      result
    end

    protected

    def coerce(_field_id, value, _localized, _includes)
      value
    end
  end
end
