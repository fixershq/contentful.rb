# frozen_string_literal: true

require_relative 'fields_resource'
require_relative 'content_type_cache'

module Contentful
  # Resource class for Entry.
  # @see _ https://www.contentful.com/developers/documentation/content-delivery-api/#entries
  class Entry < FieldsResource
    # Returns true for resources that are entries
    def entry?
      true
    end

    private

    def coerce(field_id, value, localized, includes)
      return build_nested_resource(value, localized, includes) if Support.link?(value)
      return coerce_link_array(value, localized, includes) if Support.link_array?(value)

      super(field_id, value, localized, includes)
    end

    def coerce_link_array(value, localized, includes)
      items = []
      value.each do |link|
        items << build_nested_resource(link, localized, includes)
      end

      items
    end

    # Maximum include depth is 10 in the API, but we raise it to 20 (by default),
    # in case one of the included items has a reference in an upper level,
    # so we can keep the include chain for that object as well
    # Any included object after the maximum include resolution depth will be just a Link
    def build_nested_resource(value, localized, includes)
      if @depth < 10
        resource = Support.resource_for_link(value, includes)
        return resolve_include(resource, localized, includes) unless resource.nil?
      end

      build_link(value)
    end

    def resolve_include(resource, localized, includes)
      ResourceBuilder.new(
        resource,
        default_locale: default_locale,
        resource_mapping: resource_mapping,
        entry_mapping: entry_mapping,
        includes: includes,
        localized: localized,
        depth: @depth + 1
      ).run
    end

    def known_link?(name)
      field_name = name.to_sym
      return true if known_contentful_object?(fields[field_name])
      fields[field_name].is_a?(Enumerable) && fields[field_name].any? { |object| known_contentful_object?(object) }
    end

    def known_contentful_object?(object)
      (object.is_a?(Contentful::Entry) || object.is_a?(Contentful::Asset))
    end

    protected

    def repr_name
      "#{super}[#{sys[:content_type].id}]"
    end
  end
end
