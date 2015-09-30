require 'rails_helper'

describe 'requests/success.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:request) { create(:page, user: user) }
  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
  end
  it 'has an icon and h1 heading' do
    render
    expect(rendered).to have_css('.glyphicon.glyphicon-ok[aria-hidden="true"]')
    expect(rendered).to have_css('h1', text: 'Request complete')
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
    describe 'for webauth users' do
      let(:user) { create(:webauth_user) }
      it 'gives their stanford-email address' do
        render
        expect(rendered).to have_css('dt.sr-only', text: 'Requested by')
        expect(rendered).to have_css('dd', text: 'some-webauth-user@stanford.edu')
      end
    end
    describe 'for non-webauth useres' do
      let(:user) { create(:non_webauth_user) }
      it 'gives their name and email (in parens)' do
        render
        expect(rendered).to have_css('dt.sr-only', text: 'Requested by')
        expect(rendered).to have_css('dd', text: 'Jane Stanford (jstanford@stanford.edu)')
      end
    end
  end

  describe 'notification information' do
    context 'for a normal request made by a sponsor of a proxy group' do
      let(:user) { create(:webauth_user) }

      before do
        allow(user).to receive(:sponsor?).and_return(true)
      end

      it 'is displayed as an individual request' do
        render
        expect(rendered).to include 'Individual Request'
        expect(rendered).to include 'We&#39;ve sent a copy of this request to your email.'
      end
    end

    context 'for requests on behalf of a proxy group' do
      let(:user) { create(:library_id_user) }

      before do
        request.proxy = true
      end

      it 'is shared with the proxy group' do
        render
        expect(rendered).to include 'Shared with your proxy group'
        expect(rendered).to include <<-EOS.strip
          We&#39;ve sent a copy of this request to your email and to the designated notification address.
        EOS
      end
    end

    context 'for webauth users' do
      let(:user) { create(:webauth_user) }

      it 'indicates an email was sent' do
        render
        expect(rendered).to include user.to_email_string
        expect(rendered).to include 'We&#39;ve sent a copy of this request to your email.'
      end
    end

    context 'for name + email users' do
      let(:user) { create(:non_webauth_user) }

      it 'indicates an email was sent' do
        render
        expect(rendered).to include user.to_email_string
        expect(rendered).to include 'We&#39;ve sent a copy of this request to your email.'
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

  describe 'for medidated pages' do
    describe 'ad-hoc items' do
      let(:request) { create(:mediated_page_with_holdings, user: user, ad_hoc_items: ['ZZZ 123', 'ZZZ 321']) }
      before { render }
      it 'are displayed when they are present' do
        expect(rendered).to have_css('dt', text: 'Additional item(s)')
        expect(rendered).to have_css('dd', text: 'ZZZ 123')
        expect(rendered).to have_css('dd', text: 'ZZZ 321')
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
