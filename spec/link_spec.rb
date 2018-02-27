require 'spec_helper'

describe Contentful::Link do
  let(:client) { create_client }
  let(:entry) { vcr('entry') { create_client.entry('nyancat') } }
  let(:link) { entry.space }
  let(:content_type_link) { entry.content_type }

  describe 'SystemProperties' do
    it 'has #id' do
      expect(link.id).to eq 'cfexampleapi'
    end

    it 'has #type' do
      expect(link.type).to eq 'Link'
    end

    it 'has #link_type' do
      expect(link.link_type).to eq 'Space'
    end
  end

  describe '#resolve' do
    it 'queries the api for the resource' do
      vcr('space')do
        expect(link.resolve(client)).to be_a Contentful::Space
      end
    end

    it 'queries the api for the resource (different link object)' do
      vcr('content_type')do
        expect(content_type_link.resolve(client)).to be_a Contentful::ContentType
      end
    end
  end
end
