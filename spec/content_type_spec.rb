require 'spec_helper'

describe Contentful::ContentType do
  let(:content_type) { vcr('content_type') { create_client.content_type 'cat' } }

  describe 'SystemProperties' do
    it 'has #id' do
      expect(content_type.id).to eq 'cat'
    end

    it 'has #type' do
      expect(content_type.type).to eq 'ContentType'
    end
  end

  describe 'Properties' do
    it 'has #name' do
      expect(content_type.name).to eq 'Cat'
    end

    it 'has #description' do
      expect(content_type.description).to eq 'Meow.'
    end

    it 'has #fields' do
      expect(content_type.fields).to be_a Array
      expect(content_type.fields.first).to be_a Contentful::Field
    end

    it 'could have #display_field' do
      expect(content_type).to respond_to :display_field
    end
  end
end
