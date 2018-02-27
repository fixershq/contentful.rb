# frozen_string_literal: true

require_relative 'base_resource'
require_relative 'field'
require_relative 'support'

module Contentful
  # Resource Class for Content Types
  # https://www.contentful.com/developers/documentation/content-delivery-api/#content-types
  class ContentType < BaseResource
    attr_reader :name, :description, :fields, :display_field

    def initialize(json, **rest)
      super

      @name = json.fetch('name', nil)
      @description = json.fetch('description', nil)
      @fields = json.fetch('fields', []).map { |field| Field.new(field) }
      @display_field = json.fetch('displayField', nil)
    end

    # Field definition for field
    def field_for(field_id)
      fields.detect { |f| Support.snakify(f.id) == Support.snakify(field_id) }
    end

    protected

    def repr_name
      "#{super}[#{name}]"
    end
  end
end
