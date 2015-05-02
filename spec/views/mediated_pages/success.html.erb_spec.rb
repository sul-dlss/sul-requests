require 'rails_helper'

describe 'mediated_pages/success.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:mediated_page) { create(:mediated_page, user: user) }
  before do
    assign(:mediated_page, mediated_page)
    allow(view).to receive_messages(current_user: user)
  end
  it 'should have an icon and h1 heading' do
    render
    expect(rendered).to have_css('.glyphicon.glyphicon-ok[aria-hidden="true"]')
    expect(rendered).to have_css('h1', text: 'Request complete')
  end
  describe 'metadata' do
    let(:mediated_page) do
      create(
        :mediated_page,
        origin: 'SPEC-COLL',
        destination: 'SPEC-COLL',
        user: user,
        data: {
          'comments' => 'I want this item!'
        }
      )
    end
    before { render }
    it 'should have item title information' do
      expect(rendered).to have_css('h2', text: 'Title of MediatedPage 1234')
    end
    it 'should have the destination library' do
      expect(rendered).to have_css('dt', text: 'Must be used in')
      expect(rendered).to have_css('dd', text: 'Special Collections')
    end
    it 'should have a comments section' do
      expect(rendered).to have_css('dt', text: 'Item(s) requested')
      expect(rendered).to have_css('dd', text: 'I want this item!')
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
