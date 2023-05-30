# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_request_status_information.html.erb' do
  let(:user) { create(:sso_user) }
  let(:request) { create(:scan, user:) }

  before do
    allow(view).to receive_messages(current_request: request)
  end

  describe 'display request destination' do
    context 'when there is no delivery destination' do
      it "doesn't display the 'Deliver to' field" do
        render
        expect(rendered).not_to have_content('Will be delivered to')
      end
    end

    context 'when there is a delivery destination' do
      let(:request) { create(:page_mp_mediated_page, user:) }

      it "displays the 'Deliver to' field" do
        render
        expect(rendered).to have_content('Will be delivered to')
      end
    end
  end
end
