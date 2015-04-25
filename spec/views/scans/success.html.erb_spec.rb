require 'rails_helper'

describe 'scans/success.html.erb' do
  let(:scan) { Scan.new }
  let(:user) { User.new }
  before do
    assign(:scan, scan)
    allow(scan).to receive_messages(user: user)
    allow(view).to receive_messages(current_user: user)
  end
  it 'should have an icon and h1 heading' do
    render
    expect(rendered).to have_css('.glyphicon.glyphicon-ok[aria-hidden="true"]')
    expect(rendered).to have_css('h1', text: 'Request complete')
  end
  describe 'metadata' do
    let(:scan) do
      Scan.new(
        data: { 'page_range' => 'Range-123', 'section_title' => 'Section-123', 'authors' => 'Author-123' }
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
      let(:user) { User.new(webauth: 'somebody') }
      it 'should give their stanford-email address' do
        render
        expect(rendered).to have_css('dd', text: 'somebody@stanford.edu')
      end
    end
    describe 'for non-webauth useres' do
      let(:user) { User.new(name: 'Jane Stanford', email: 'jstanford@stanford.edu') }
      it 'should give their name and email (in parens)' do
        render
        expect(rendered).to have_css('dd', text: 'Jane Stanford (jstanford@stanford.edu)')
      end
    end
  end
end
