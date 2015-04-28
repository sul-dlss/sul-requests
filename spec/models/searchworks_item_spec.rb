require 'rails_helper'

describe SearchworksItem do
  let(:subject) { SearchworksItem.new('123') }

  describe '#uri' do
    it 'should return the base uri from the settings.yml file' do
      expect(subject.send(:uri)).to eq('http://searchworks.stanford.edu')
    end
  end
  describe '#url' do
    it 'should return a url for the searchworks api' do
      expect(subject.send(:url)).to eq('http://searchworks.stanford.edu/view/123.mobile?covers=false')
    end
  end
  describe '#xml' do
    it 'should return xml as the body of the response object' do
      expect(subject.send(:xml)).to start_with('<?xml version="1.0" encoding="utf-8"?>')
    end
  end
  describe '#response' do
    before do
      allow(subject).to receive_messages(xml: standard_searchworks_response)
    end
    describe '#response_xml?' do
      it 'should have a <response> tag in the xml' do
        expect(subject.send(:response_xml)).to have_key('LBItem')
      end
    end
    describe '#item_xml?' do
      it 'should have a <response>/<LBItem> tag in the xml' do
        expect(subject.send(:item_xml)).to have_key('title')
      end
    end
    describe '#title' do
      it 'should have a title string' do
        expect(subject.title).to eq('A la francaise')
      end
    end
  end
  describe '#response' do
    before do
      allow(subject).to receive_messages(xml: empty_item_response)
    end
    describe '#title' do
      it 'should have an empty title string' do
        expect(subject.title).to be_empty
      end
    end
  end

  let(:empty_item_response) do
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <response>
    <LBItem>
    </LBItem>
    </response>"
  end

  let(:standard_searchworks_response) do
    "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <response>
      <LBItem>
        <item_id>123</item_id>
        <full_title>A la francaise; 3 pieces pour quintette a vent.</full_title>
        <title>A la francaise</title>
        <authors>
          <author>Amell\xC3\xA9r, Andr\xC3\xA9, 1912-1990</author>
        </authors>
        <formats>
          <format>Music - Score</format>
        </formats>
        <contents>
          <content>1.Prelude, Fughetto.- 2.Grave.- 3.Rondo.</content>
        </contents>
        <imprint>Paris, Editions Musicales Transatlantiques, c1973.</imprint>
        <record_url label=\"View Item in SearchWorks\">
          <![CDATA[http://searchworks.stanford.edu/view/123]]>
        </record_url>
        <holdings>
          <library name=\"Music Library\">
            <location name=\"Scores\">
              <item>
                <callnumber>M557 .A498 A1 PTS</callnumber>
                </item>
            </location>
          </library>
        </holdings>
      </LBItem>
    </response>"
  end
end
