# frozen_string_literal: true

require_relative 'fields_resource'
require_relative 'file'

module Contentful
  # Resource class for Asset.
  # https://www.contentful.com/developers/documentation/content-delivery-api/#assets
  class Asset < FieldsResource
    FIELDS = %w(fileName contentType details url).freeze

    # @private
    def marshal_dump
      {
        configuration: @configuration,
        raw: raw
      }
    end

    # @private
    def marshal_load(raw_object)
      super(raw_object)
      create_files!
    end

    # @private
    def inspect
      "<#{repr_name} id='#{id}' url='#{url}'>"
    end

    def initialize(*)
      super
      create_files!
    end

    # Generates a URL for the Contentful Image API
    #
    # @param [Hash] options
    # @option options [Integer] :width
    # @option options [Integer] :height
    # @option options [String] :format
    # @option options [String] :quality
    # @option options [String] :focus
    # @option options [String] :fit
    # @option options [String] :fl File Layering - 'progressive'
    # @see _ https://www.contentful.com/developers/documentation/content-delivery-api/#image-asset-resizing
    #
    # @return [String] Image API URL
    def image_url(options = {})
      query = {
        w: options[:w] || options[:width],
        h: options[:h] || options[:height],
        fm: options[:fm] || options[:format],
        q: options[:q] || options[:quality],
        f: options[:f] || options[:focus],
        fit: options[:fit],
        fl: options[:fl]
      }.reject { |_k, v| v.nil? }

      if query.empty?
        file.url
      else
        "#{file.url}?#{URI.encode_www_form(query)}"
      end
    end

    alias url image_url


    def description
      fields[:description]
    end

    def file(wanted_locale = nil)
      fields(wanted_locale)[:file]
    end

    private

    def create_files!
      file_json = raw.fetch('fields', {}).fetch('file', nil)
      return if file_json.nil?

      is_localized = file_json.keys.none? { |f| FIELDS.include? f }
      if is_localized
        locales.each do |locale|
          @fields[locale][:file] = ::Contentful::File.new(file_json[locale.to_s] || {})
        end
      else
        @fields[internal_resource_locale][:file] = ::Contentful::File.new(file_json)
      end
    end
  end
end
