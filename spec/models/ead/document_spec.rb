# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::Document do
  subject(:document) { described_class.new(eadxml) }

  let(:eadxml) do
    Nokogiri::XML(File.read('spec/fixtures/sc0097.xml')).tap(&:remove_namespaces!)
  end

  describe '#date' do
    it 'extracts the inclusive date' do
      expect(document.date).to eq('1962-2018')
    end
  end

  describe Ead::Document::Node, '.from' do
    def build_node(xml)
      node = Nokogiri::XML(xml).tap(&:remove_namespaces!).root
      described_class.from(node)
    end

    it 'creates an Item for a series-level node with no children' do
      result = build_node(<<~XML)
        <c02 level="series">
          <did>
            <unittitle>1-38</unittitle>
            <container type="Box">1</container>
          </did>
        </c02>
      XML
      expect(result).to be_a(Ead::Document::Item)
      expect(result.top_container).to eq('Box 1')
    end

    it 'creates a Node for a series-level node with children' do
      result = build_node(<<~XML)
        <c01 level="series">
          <did><unittitle>Papers</unittitle></did>
          <c02 level="file">
            <did><unittitle>Chapter 1</unittitle></did>
          </c02>
        </c01>
      XML
      expect(result).to be_a(described_class)
      expect(result).not_to be_a(Ead::Document::Item)
    end
  end

  describe Ead::Document::Item do
    def build_item(xml)
      node = Nokogiri::XML(xml).tap(&:remove_namespaces!).root
      described_class.new(node)
    end

    describe '#digital_only?' do
      it 'returns true for items with only a DAO and no container' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle>Email about first meeting</unittitle>
              <dao href="https://purl.stanford.edu/mq258ch0268" title="Email about first meeting" />
            </did>
          </c02>
        XML
        expect(item).to be_digital_only
      end

      it 'returns false for items with both a container and a DAO' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle>Mathematical writing</unittitle>
              <container type="Box">1</container>
              <dao href="http://purl.stanford.edu/ns905zh5886" title="Mathematical writing" />
            </did>
          </c02>
        XML
        expect(item).not_to be_digital_only
      end

      it 'returns false for items with a container and no DAO' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle>Dedication</unittitle>
              <container type="Box">1</container>
              <container type="folder">1</container>
            </did>
          </c02>
        XML
        expect(item).not_to be_digital_only
      end

      it 'returns false for items with neither a container nor a DAO' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle>Loose document</unittitle>
            </did>
          </c02>
        XML
        expect(item).not_to be_digital_only
      end
    end

    describe '#extref_href' do
      it 'returns the extref href from the component' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle> "Tangible non-sexist approach needed" article</unittitle>
              <unitid type="ark">
                <extref actuate="onLoad" href="https://archives.stanford.edu/findingaid/ark:/22236/s1f02438da-9c3b-4ac4-9206-6a95f69dde75" show="new">Archival Resource Key</extref>
              </unitid>
            </did>
          </c02>
        XML
        expect(item.extref_href).to eq('https://archives.stanford.edu/findingaid/ark:/22236/s1f02438da-9c3b-4ac4-9206-6a95f69dde75')
      end

      it 'returns nil when no DAO is present' do
        item = build_item(<<~XML)
          <c02 level="file">
            <did>
              <unittitle> "Tangible non-sexist approach needed" article</unittitle>
            </did>
          </c02>
        XML
        expect(item.extref_href).to be_nil
      end
    end
  end
end
