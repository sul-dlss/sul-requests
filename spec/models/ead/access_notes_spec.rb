# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ead::AccessNotes do
  def access_note(text, heading: nil)
    Nokogiri::XML::Builder.new do |xml|
      xml.accessrestrict do
        xml.head heading if heading
        xml.p text
      end
    end.doc.root
  end

  def displayed_text(text)
    described_class.new([access_note(text)]).for_display.sole.text.squish
  end

  {
    'Open for research. Note that material must be requested at least 36 hours in advance of intended use.' => 'Open for research.',
    'Open for research; material must be requested at least two business days in advance of intended use.' => 'Open for research.',
    'Open for research; material must be requested at least three business days of intended use.' => 'Open for research.',
    'Open for research; material must be requested at least 43 business days in advance of intended use.' => 'Open for research.',
    'The materials are open for research and must be requested at least 36 hours in advance of intended use.' =>
      'The materials are open for research.',
    'Materials are stored off-site and must be requested at least 24 hours in advance of use.' => 'Materials are stored off-site.',
    'Open for research. Note that material must be requested at least 36 hours in advance of intended use' => 'Open for research.'
  }.each do |original, expected|
    it "removes only the recognized lead time clause from #{original.inspect}" do
      expect(displayed_text(original)).to eq(expected)
    end
  end

  it 'preserves restrictions before and after a semicolon lead time clause' do
    text = 'Boxes 42 and 45 are restricted until 2085; materials must be requested at least 48 hours in advance of intended use. ' \
           'No photocopies may be made.'
    expect(displayed_text(text)).to eq('Boxes 42 and 45 are restricted until 2085. No photocopies may be made.')
  end

  it 'handles missing spaces between sentences and repeated clauses' do
    text = 'Open for research; material must be requested at least two business days in advance of intended use.' \
           'Contact the Archive. Materials must be requested at least 36 hours in advance of intended use.'
    expect(displayed_text(text)).to eq('Open for research. Contact the Archive.')
  end

  it 'keeps unknown lead time wording and other advance notice instructions intact' do
    text = 'Materials must be requested at least five days ahead. Media materials require at least two weeks advance notice.'
    expect(displayed_text(text)).to eq(text)
  end

  it 'keeps a lead time clause with an unrecognized qualification intact' do
    text = 'Materials must be requested at least 36 hours in advance of intended use unless staff approve otherwise.'
    expect(displayed_text(text)).to eq(text)
  end

  it 'preserves paragraphs, inline markup, and links without changing the source XML' do
    note = Nokogiri::XML(<<~XML).root
      <accessrestrict><head>Access Restrictions</head>
        <p>Open for research. Note that material must be requested at least 36 hours in advance of intended use.
          Read <title>the guide</title> and <extref href="https://example.com/access">contact staff</extref>.</p>
        <p>Materials must be requested at least 48 hours in advance of intended use.</p>
        <p>Digital files are closed until processed.</p>
      </accessrestrict>
    XML
    original = note.to_xml
    result = described_class.new([note]).for_display.first
    expect(result.xpath('p').size).to eq(2)
    expect(result.xpath('p').map { |paragraph| paragraph.text.squish }).to eq(
      ['Open for research. Read the guide and contact staff.', 'Digital files are closed until processed.']
    )
    expect(result.at_xpath('head').text).to eq('Access Restrictions')
    expect(result.at_xpath('.//title').text).to eq('the guide')
    expect(result.at_xpath('.//extref')['href']).to eq('https://example.com/access')
    expect(note.to_xml).to eq(original)
  end

  it 'omits a note whose only body text was the lead time instruction' do
    note = Nokogiri::XML('<accessrestrict><head>Access</head><p>Materials must be requested at least 48 hours ' \
                         'in advance of intended use.</p></accessrestrict>').root
    expect(described_class.new([note]).for_display).to be_empty
  end

  describe '#restrictions' do
    it 'omits notes that only state access is unrestricted' do
      note = access_note('Open for research. Note that material must be requested at least 36 hours in advance of intended use.')
      expect(described_class.new([note]).restrictions).to be_empty
    end

    it 'keeps every note when any note in the group is restricted' do
      notes = [access_note('Open for research.'), access_note('Closed until 2055.')]
      expect(described_class.new(notes).restrictions.map { |note| note.text.squish }).to eq(['Open for research.', 'Closed until 2055.'])
    end
  end

  describe '.unrestricted?' do
    [
      'This collection is open for research.',
      'The materials are open for research use.',
      'Materials are open for research use.',
      'Open for research.',
      "  OPEN for research\n use. ",
      'None.',
      'No restrictions.',
      'There are no restrictions on access.',
      'Access unrestricted.',
      'Open for research. Contact the Archive for assistance.',
      'Open for research. Contact the Archive of Recorded Sound for assistance.',
      'Open for research. Contact Archive of Recorded Sound for assistance.',
      'Open for research. Contact the Library for assistance.',
      'Open for research. Contact the Library for assistance'
    ].each do |text|
      it "is true for #{text.inspect}" do
        expect(described_class.unrestricted?([access_note(text)])).to be true
      end
    end

    [
      'Access restricted until 2055.',
      'Restricted until 2025.',
      'May not be used without permission of the Archivist.',
      'Access to digital content is restricted to the Special Collections Reading Room.',
      'Use restricted due to mold on original recording.',
      'Do not remove the robe from its box.',
      'Warning: this book contains graphic images.',
      'Materials are open for research use. Audio-visual materials are not available in original format.',
      'Open for research except for materials restricted for legal and privacy reasons.',
      'None. Except for closed files.',
      'Contact the Archive for assistance.',
      'Restricted until 2055. Contact the Archive for assistance.',
      'Open for research. Contact the Archive for assistance with restricted boxes.',
      'Collection is open for research. Listening appointments may require 24 hours notice. Contact the Archive Operations Manager.',
      'Open for research. Contact the Archive of Recorded Sound for assistance. ' \
      'There are traces of inactive mold on the edges of some of the tapes.'
    ].each do |text|
      it "is false for #{text.inspect}" do
        expect(described_class.unrestricted?([access_note(text)])).to be false
      end
    end

    it 'is false when any note in the group is restricted' do
      notes = [access_note('This collection is open for research.'), access_note('Closed until 2055.')]
      expect(described_class.unrestricted?(notes)).to be false
    end

    it 'ignores the note heading' do
      expect(described_class.unrestricted?([access_note('Open for research.', heading: 'Access Restrictions')])).to be true
    end
  end
end
