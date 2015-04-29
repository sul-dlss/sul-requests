require 'rails_helper'

describe 'scans/success.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:scan) { create(:scan, user: user) }
  before do
    assign(:scan, scan)
    allow(view).to receive_messages(current_user: user)
  end
  it 'should have an icon and h1 heading' do
    render
    expect(rendered).to have_css('.glyphicon.glyphicon-ok[aria-hidden="true"]')
    expect(rendered).to have_css('h1', text: 'Request complete')
  end
  it 'should have the title in an h2 heading' do
    render
    expect(rendered).to have_css('h2', text: 'Title for Scan 1234')
  end
  describe 'metadata' do
    let(:scan) do
      create(
        :scan,
        user: user,
        data: { 'page_range' => 'Range-123',
                'section_title' => 'Section-123',
                'authors' => 'Author-123'
              }
      )
    end
    before { render }
    it 'should have the page range' do
      expect(rendered).to have_css('dt', text: 'Page range')
      expect(rendered).to have_css('dd', text: 'Range-123')
    end
    it 'should have a section title' do
      expect(rendered).to have_css('dt', text: 'Article title')
      expect(rendered).to have_css('dd', text: 'Section-123')
    end
    it 'should have a section title' do
      expect(rendered).to have_css('dt', text: 'Author(s)')
      expect(rendered).to have_css('dd', text: 'Author-123')
    end
  end
  describe 'user information' do
    describe 'for webauth users' do
      let(:user) { create(:webauth_user) }
      it 'should give their stanford-email address' do
        render
        expect(rendered).to have_css('dd', text: 'some-webauth-user@stanford.edu')
      end
    end
    describe 'for non-webauth useres' do
      let(:user) { create(:non_webauth_user) }
      it 'should give their name and email (in parens)' do
        render
        expect(rendered).to have_css('dd', text: 'Jane Stanford (jstanford@stanford.edu)')
      end
    end
  end
end
