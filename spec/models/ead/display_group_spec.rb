# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::DisplayGroup do
  def build_node(xml)
    node = Nokogiri::XML(xml).tap(&:remove_namespaces!).root
    Ead::Document::Node.from(node)
  end

  describe '.build_display_groups' do
    it 'creates an ItemContainer for a series-level node with a container but no children' do
      item = build_node(<<~XML)
        <c02 level="series">
          <did>
            <unittitle>1-38</unittitle>
            <container type="Box">1</container>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::ItemContainer)
      expect(groups.first.title).to eq('Box 1')
    end

    it 'creates a DigitalItem for a DAO-only item' do
      item = build_node(<<~XML)
        <c02 level="file">
          <did>
            <unittitle> "Tangible non-sexist approach needed" article</unittitle>
            <unitid type="ark">
              <extref actuate="onLoad" href="https://archives.stanford.edu/findingaid/ark:/22236/s1f02438da-9c3b-4ac4-9206-6a95f69dde75" show="new">Archival Resource Key</extref>
            </unitid>
            <dao actuate="onRequest" href="https://purl.stanford.edu/cj173jr0975" role="image-service" show="new" title=" &quot;Tangible non-sexist approach needed&quot; article" type="simple">
              <daodesc>
                <p>"Tangible non-sexist approach needed" article</p>
              </daodesc>
            </dao>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::DigitalItem)
      expect(groups.first.title).to eq('"Tangible non-sexist approach needed" article')
      expect(groups.first.href).to eq('https://archives.stanford.edu/findingaid/ark:/22236/s1f02438da-9c3b-4ac4-9206-6a95f69dde75')
    end

    it 'creates an ItemWithoutContainer for items with no container and no DAO' do
      item = build_node(<<~XML)
        <c02 level="file">
          <did>
            <unittitle>Loose document</unittitle>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::ItemWithoutContainer)
    end

    it 'creates an ItemContainer when a hierarchical node has only containerless leaf children' do
      item = build_node(<<~XML)
        <c01 level="series">
          <did>
            <unittitle>Kentucky Lincoln facsimiles</unittitle>
            <unitdate>1850-1860</unitdate>
          </did>
          <c02 level="file">
            <did><unittitle>Letter 1</unittitle></did>
          </c02>
          <c02 level="file">
            <did><unittitle>Letter 2</unittitle></did>
          </c02>
        </c01>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::ItemContainer)
      expect(groups.first.title).to eq('Kentucky Lincoln facsimiles, 1850-1860')
      expect(groups.first.contents.size).to eq(2)
    end

    it 'creates a Subseries when a hierarchical node has nested hierarchy' do
      item = build_node(<<~XML)
        <c01 level="series">
          <did><unittitle>Papers</unittitle></did>
          <c02 level="subseries">
            <did><unittitle>Correspondence</unittitle></did>
            <c03 level="file">
              <did>
                <unittitle>Letter</unittitle>
                <container type="Box">1</container>
              </did>
            </c03>
          </c02>
        </c01>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::Subseries)
      expect(groups.first.title).to eq('Papers')

      expect(groups.first.contents.first).to have_attributes(hierarchy: ['Papers'])
      expect(groups.first.contents.first.contents.first).to have_attributes(hierarchy: %w[Papers Correspondence])
    end

    it 'creates an ItemContainer for items with a physical container' do
      item = build_node(<<~XML)
        <c02 level="file">
          <did>
            <unittitle>Chapter 1</unittitle>
            <container type="Box">1</container>
            <dao href="http://purl.stanford.edu/abc123" title="Chapter 1" />
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_a(Ead::DisplayGroup::ItemContainer)
      expect(groups.first.title).to eq('Box 1')
    end
  end
end
