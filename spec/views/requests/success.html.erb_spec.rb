# frozen_string_literal: true

require 'rails_helper'

describe 'requests/success.html.erb' do
  let(:user) { create(:sso_user) }
  let(:request) { create(:page, user: user) }

  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
  end

  describe 'symphony success' do
    it 'has success text for successful requests' do
      render
      expect(rendered).to have_css('h1#dialogTitle', text: /We're working on it/)
    end
  end

  it 'has item title information' do
    render
    expect(rendered).to have_css('h2', text: request.item_title)
  end

  it 'has the destination library' do
    request.destination = 'GREEN'
    render
    expect(rendered).to have_css('dt', text: 'Deliver to')
    expect(rendered).to have_css('dd', text: 'Green Library')
  end

  it 'has the estimated delivery' do
    request.estimated_delivery = 'Some day, Before 10am'
    render
    expect(rendered).to have_css('dt', text: 'Estimated delivery')
    expect(rendered).to have_css('dd', text: 'Some day, Before 10am')
  end

  it 'has the needed date' do
    request.needed_date = Time.zone.today
    render
    expect(rendered).to have_css('dt', text: 'Needed on')
    expect(rendered).to have_css('dd', text: l(Time.zone.today, format: :long))
  end

  describe 'user information' do
    describe 'for SSO users' do
      let(:user) { create(:sso_user) }

      it 'gives their stanford-email address' do
        render
        expect(rendered).to have_content('some-sso-user@stanford.edu')
      end
    end

    describe 'for non-SSO useres' do
      let(:user) { create(:non_sso_user) }

      it 'gives their email' do
        render
        expect(rendered).to have_content('jstanford@stanford.edu')
      end
    end
  end

  describe 'notification information' do
    context 'for a normal request made by a sponsor of a proxy group' do
      let(:user) { create(:sso_user) }

      before do
        allow(user).to receive(:sponsor?).and_return(true)
      end

      it 'is displayed as an individual request' do
        render
        expect(rendered).to include 'We\'ll send you an email'
      end
    end

    context 'for requests on behalf of a proxy group' do
      let(:request) { build(:page, user: user) }
      let(:user) { create(:library_id_user, email: 'some-address@example.com') }

      before do
        request.proxy = true
      end

      it 'is shared with the proxy group' do
        render
        expect(rendered).to include(
          'We\'ll send an email to you at <strong>some-address@example.com</strong> and to the designated notification'
        )
      end
    end

    context 'for SSO users' do
      let(:user) { create(:sso_user) }

      it 'indicates an email will be sent' do
        render
        expect(rendered).to include user.email_address
        expect(rendered).to include(
          'We\'ll send you an email at <strong>some-sso-user@stanford.edu</strong> when processing is complete.'
        )
      end
    end

    context 'for name + email users' do
      let(:user) { create(:non_sso_user) }

      it 'indicates an email will be sent' do
        render
        expect(rendered).to include user.email_address
        expect(rendered).to include(
          'We\'ll send you an email at <strong>jstanford@stanford.edu</strong> when processing is complete.'
        )
      end
    end
  end

  describe 'for scans' do
    let(:request) do
      create(
        :scan_with_holdings,
        user: user,
        data: {
          'page_range' => 'Range of pages', 'section_title' => 'Title of section', 'authors' => 'The Author'
        }
      )
    end

    describe 'metadata' do
      before { render }

      it 'has a page range section' do
        expect(rendered).to have_css('dt', text: 'Page range')
        expect(rendered).to have_css('dd', text: 'Range of pages')
      end

      it 'has a article title section' do
        expect(rendered).to have_css('dt', text: 'Title of article or chapter')
        expect(rendered).to have_css('dd', text: 'Title of section')
      end

      it 'has an authors section' do
        expect(rendered).to have_css('dt', text: 'Author(s)')
        expect(rendered).to have_css('dd', text: 'The Author')
      end
    end
  end

  describe 'for mediated pages' do
    describe 'item level comments' do
      let(:request) { create(:mediated_page_with_holdings, user: user, item_comment: ['Volume 666 only']) }

      before do
        expect(request).to receive(:item_commentable?).and_return(true)
        render
      end

      it 'are displayed when they are present' do
        expect(rendered).to have_css('dt', text: 'Item(s) requested')
        expect(rendered).to have_css('dd', text: 'Volume 666 only')
      end
    end

    describe 'request level comments' do
      let(:request) { create(:mediated_page_with_holdings, user: user, request_comment: 'Here today, gone tomorrow') }

      before do
        render
      end

      it 'are displayed when they are present' do
        expect(rendered).to have_css('dt', text: 'Comment')
        expect(rendered).to have_css('dd', text: 'Here today, gone tomorrow')
      end
    end

    describe 'selected items' do
      let(:request) { create(:mediated_page_with_holdings, user: user, barcodes: %w(12345678 23456789)) }

      before { render }

      it 'are displayed when there are multiple selected' do
        expect(rendered).to have_css('dt', text: 'Item(s) requested')
        expect(rendered).to have_css('dd', text: 'ABC 123')
        expect(rendered).to have_css('dd', text: 'ABC 456')
      end
    end
  end
end
