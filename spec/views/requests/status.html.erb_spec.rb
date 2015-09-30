require 'rails_helper'

describe 'requests/status.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:request) { create(:page, user: user) }
  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
  end
  it 'has an icon and h1 heading' do
    render
    expect(rendered).to have_css('h1', text: 'Status of your request')
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

      it 'has an article title section' do
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

      context 'with abnormal request statuses' do
        before do
          allow_any_instance_of(ItemStatus).to receive(:msgcode).and_return('P001B')
          render
        end

        it 'displays abnormal request status messages' do
          expect(rendered).to have_css('dd', text: 'ABC 123 (delivery may be delayed)')
        end
      end
    end
  end
end
