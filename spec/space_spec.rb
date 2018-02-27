require 'spec_helper'

describe Contentful::Space do
  let(:space) { vcr('space') { create_client.space } }

  describe 'SystemProperties' do
    it 'has #id' do
      expect(space.id).to eq 'cfexampleapi'
    end

    it 'has #type' do
      expect(space.type).to eq 'Space'
    end
  end

  describe 'Properties' do
    it 'has #name' do
      expect(space.name).to eq 'Contentful Example API'
    end

    it 'has #locales' do
      expect(space.locales).to be_a Array
      expect(space.locales.first).to be_a Contentful::Locale
    end
  end
end
