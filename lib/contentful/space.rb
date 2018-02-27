# frozen_string_literal: true

require_relative 'base_resource'
require_relative 'locale'

module Contentful
  # Resource class for Space.
  # https://www.contentful.com/developers/documentation/content-delivery-api/#spaces
  class Space < BaseResource
    attr_reader :name, :locales

    def initialize(json, **rest)
      super

      @name = json.fetch('name', nil)
      @locales = json.fetch('locales', []).map { |locale| Locale.new(locale) }
    end

    # @private
    def reload(client = nil)
      return client.space unless client.nil?

      false
    end
  end
end
