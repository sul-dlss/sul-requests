# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_request_status_information.html.erb' do
  let(:user) { create(:sso_user) }

  before do
    allow(view).to receive_messages(current_request: request)
    allow(Settings.ils.bib_model.constantize).to receive(:fetch)
  end

  describe 'display request destination' do
    context 'when there is no delivery destination (e.g. for a scan)' do
      let(:request) { build_stubbed(:scan, :without_validations, :with_item_title, user:) }

      it "doesn't display the 'Deliver to' field" do
        render
        expect(rendered).to have_no_content('Will be delivered to')
      end
    end

    context 'when there is a delivery destination' do
      let(:request) { build_stubbed(:page_mp_mediated_page, user:, barcodes: ['12345678']) }

      it "displays the 'Deliver to' field" do
        render
        expect(rendered).to have_content('Will be delivered to')
      end
    end
  end
end
