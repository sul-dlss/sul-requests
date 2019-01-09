# frozen_string_literal: true

require 'rails_helper'

describe 'requests/status.html.erb' do
  let(:user) { create(:webauth_user) }
  let(:request) { create(:page, user: user) }

  before do
    allow(view).to receive_messages(current_request: request)
    allow(view).to receive_messages(current_user: user)
    allow(controller).to receive_messages(current_user: user)
  end

  it 'has an icon and h1 heading' do
    render
    expect(rendered).to have_css('h1', text: 'Status of your request')
  end

  describe 'Status' do
    context 'for Hold/Recalls sent to BorrowDirect' do
      before { request.via_borrow_direct = true }

      it 'has a hard-coded status indicating we are working on getting the item' do
        render
        expect(rendered).to have_css('dt', text: 'Status')
        expect(rendered).to have_css('dd', text: "We're working on getting this item for you.")
      end
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

  describe 'ad-hoc items' do
    let(:request) { create(:mediated_page_with_holdings, user: user, ad_hoc_items: ['ZZZ 123', 'ZZZ 321']) }

    before { render }

    it 'are displayed when they are present' do
      expect(rendered).to have_css('dt', text: 'Additional item(s)')
      expect(rendered).to have_css('dd', text: 'ZZZ 123')
      expect(rendered).to have_css('dd', text: 'ZZZ 321')
    end
  end

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

    before { render }

    it 'are displayed when they are present' do
      expect(rendered).to have_css('dt', text: 'Comment')
      expect(rendered).to have_css('dd', text: 'Here today, gone tomorrow')
    end
  end

  describe 'selected items' do
    let(:request) do
      create(
        :mediated_page_with_holdings,
        user: user,
        barcodes: %w(12345678 23456789),
        symphony_response_data: build(:symphony_request_with_mixed_status)
      )
    end

    before { render }

    it 'are displayed when there are multiple selected' do
      expect(rendered).to have_css('dt', text: 'Item(s) requested')
      expect(rendered).to have_css('dd', text: 'ABC 123')
      expect(rendered).to have_css('dd', text: 'ABC 456')
    end

    context 'with abnormal request statuses' do
      it 'displays abnormal request status messages' do
        expect(rendered).to have_css('dd', text: 'Attention: ABC 456 Item not found in catalog')
      end
    end
  end
end
