# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EadRequestsHelper do
  describe '#access_note_body' do
    subject(:body) { Capybara.string(helper.access_note_body(note)) }

    let(:note) do
      Nokogiri::XML(<<~XML).root
        <accessrestrict><head>Access Restrictions</head>
          <p>Read <title>this title</title> first.</p>
          <p><extref href="https://library.stanford.edu/contact">Contact us</extref>.</p>
          <p><extref href="javascript:alert(1)" onclick="alert(1)">Unsafe link</extref></p>
          <script>alert(1)</script>
        </accessrestrict>
      XML
    end

    it 'preserves paragraphs and safe links while converting EAD inline markup' do
      expect(body).to have_css('p', count: 3)
      expect(body).to have_css('em', text: 'this title')
      expect(body).to have_link('Contact us', href: 'https://library.stanford.edu/contact')
      expect(body).to have_no_text('Access Restrictions')
      expect(note.at_xpath('head')).to be_present
    end

    it 'removes unsafe HTML and link attributes' do
      expect(body).to have_no_css('script', visible: :all)
      expect(body).to have_no_css('[onclick]', visible: :all)
      expect(body).to have_no_css('a[href^="javascript:"]', visible: :all)
    end
  end
end
