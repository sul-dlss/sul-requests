# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::DisplayGroup do
  def build_node(xml)
    node = Nokogiri::XML(xml).tap(&:remove_namespaces!).root
    Ead::Document::Node.from(node)
  end

  describe '.build_display_groups' do
    it 'creates a selectable node for a series-level node with a container but no children' do
      item = build_node(<<~XML)
        <c02 level="series">
          <did>
            <unittitle>1-38</unittitle>
            <container type="Box">1</container>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_selectable
      expect(groups.first.title).to eq('Box 1')
    end

    it 'keeps series notes on their group and component notes on their items' do
      series = build_node(<<~XML)
        <c01><did><unittitle>Series</unittitle></did>
          <accessrestrict><p>Series access</p></accessrestrict>
          <c02><did><unittitle>Folder A</unittitle><container type="box">1</container></did></c02>
          <c02><did><unittitle>Folder B</unittitle><container type="box">1</container></did></c02>
          <c02><did><unittitle>Folder C</unittitle><container type="box">1</container></did>
            <accessrestrict><p>Folder C access</p></accessrestrict>
          </c02>
        </c01>
      XML

      group = described_class.build_display_groups([series]).first
      expect(group.access_notes.map(&:text)).to eq(['Series access'])
      expect(group.contents.size).to eq(1)
      expect(group.contents.first.access_notes).to be_empty
      expect(group.contents.first.restricted_items_count).to eq(1)
      expect(group.contents.first.contents.last.access_notes.map(&:text)).to eq(['Folder C access'])
    end

    it 'counts affected items, including nested items, rather than counting notes' do
      item = build_node(<<~XML)
        <c01><did><unittitle>Folder</unittitle><container type="box">8</container></did>
          <accessrestrict><p>Folder access.</p></accessrestrict>
          <accessrestrict><p>Additional folder instructions.</p></accessrestrict>
          <c02><did><unittitle>Part</unittitle></did>
            <c03><did><unittitle>Nested item</unittitle></did>
              <accessrestrict><p>Nested item access.</p></accessrestrict>
            </c03>
          </c02>
        </c01>
      XML

      group = described_class.build_display_groups([item]).first
      expect(group.restricted_items_count).to eq(2)
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

    it 'creates a selectable node for items with no contents and no DAO' do
      item = build_node(<<~XML)
        <c02 level="file">
          <did>
            <unittitle>Loose document</unittitle>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_selectable
    end

    it 'titles a selectable node by its date when it has no unittitle' do
      item = build_node(<<~XML)
        <c02 level="otherlevel">
          <did>
            <unitdate>25 Apr. 1901</unitdate>
          </did>
        </c02>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first.title).to eq('25 Apr. 1901')
    end

    it 'creates a selectable node when a hierarchical node has only containerless leaf children' do
      item = build_node(<<~XML)
        <c01 level="series">
          <did><unittitle>Kentucky Lincoln facsimiles</unittitle><unitdate>1850-1860</unitdate></did>
          <accessrestrict><p>Handle the facsimiles carefully.</p></accessrestrict>
          <c02 level="file">
            <did><unittitle>Letter 1</unittitle></did>
            <accessrestrict><p>Use the digital copy of Letter 1.</p></accessrestrict>
          </c02>
          <c02 level="file">
            <did><unittitle>Letter 2</unittitle></did>
          </c02>
        </c01>
      XML

      groups = described_class.build_display_groups([item])
      expect(groups.first).to be_selectable
      expect(groups.first.title).to eq('Kentucky Lincoln facsimiles, 1850-1860')
      expect(groups.first.contents.size).to eq(2)
      expect(groups.first.group_access_notes.map(&:text)).to eq(['Handle the facsimiles carefully.'])
      expect(groups.first.item_access_notes).to be_empty
      expect(groups.first.restricted_items_count).to eq(1)
      expect(groups.first.contents.first.access_notes.map(&:text)).to eq(['Use the digital copy of Letter 1.'])
    end

    it 'treats notes on a file-level node with containerless children as item notes' do
      item = build_node(<<~XML)
        <c02 level="file">
          <did><unittitle>Correspondence</unittitle></did>
          <accessrestrict><p>Restricted to staff.</p></accessrestrict>
          <c03 level="item"><did><unittitle>Letter 1</unittitle></did></c03>
        </c02>
      XML

      group = described_class.build_display_groups([item]).first
      expect(group.item_access_notes.map(&:text)).to eq(['Restricted to staff.'])
      expect(group.group_access_notes).to be_empty
    end

    it 'treats notes on a containerless leaf as item notes' do
      item = build_node(<<~XML)
        <c02><did><unittitle>Loose letter</unittitle></did>
          <accessrestrict><p>Restricted to staff.</p></accessrestrict>
        </c02>
      XML

      group = described_class.build_display_groups([item]).first
      expect(group.item_access_notes.map(&:text)).to eq(['Restricted to staff.'])
      expect(group.group_access_notes).to be_empty
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

    it 'groups components by their own container when their children have no containers' do
      series = build_node(<<~XML)
        <c01 level="series">
          <did><unittitle>Army Specialized Training Program</unittitle></did>
          <c02 level="file">
            <did><unittitle>Tests</unittitle><container type="Box">8</container><container type="folder">213</container></did>
            <c03 level="file"><did><unittitle>Test 1</unittitle></did></c03>
          </c02>
          <c02 level="file">
            <did><unittitle>Reports</unittitle><container type="Box">8</container><container type="folder">214</container></did>
            <c03 level="file"><did><unittitle>Report 1</unittitle></did></c03>
          </c02>
        </c01>
      XML

      groups = described_class.build_display_groups(series.contents)
      expect(groups.map(&:title)).to eq(['Box 8'])
      expect(groups.first.contents.map(&:folder)).to eq(%w[213 214])
    end

    it 'creates a selectable node for items with a physical container' do
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
      expect(groups.first).to be_selectable
      expect(groups.first.title).to eq('Box 1')
    end
  end
end
