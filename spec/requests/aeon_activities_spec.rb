# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Aeon activities' do
  let(:user) { create(:sso_user) }
  let(:aeon_user) { Aeon::User.new(username: user.email_address, first_name: 'Jane', last_name: 'Stanford') }
  let(:co_member) { Aeon::User.new(username: 'mctesterson@example.com', first_name: 'Testing McTesterson') }
  let(:activity) { build(:aeon_activity, users: [aeon_user, co_member]) }
  let(:own_request) do
    build(:aeon_request, :submitted, activity_id: 1, username: aeon_user.username, item_author: 'Knuth, Donald',
                                     call_number: 'SC0097', item_volume: 'Box 1', item_date: '1962-2018',
                                     location: 'SPEC-STACKS', item_number: '36105000000000')
  end
  let(:co_member_request) do
    build(:aeon_request, :submitted, transaction_number: 308, activity_id: 1, username: co_member.username,
                                     call_number: '051 .S958')
  end
  let(:stub_aeon_client) { instance_double(AeonClient, find_user: aeon_user, activities: [activity]) }

  before do
    allow(AeonClient).to receive(:new).and_return(stub_aeon_client)
    allow(stub_aeon_client).to receive(:requests_for).with(username: aeon_user.username).and_return([own_request])
    allow(stub_aeon_client).to receive(:requests_for).with(username: co_member.username).and_return([co_member_request])
    login_as(CurrentUser.new(username: user.sunetid, shibboleth: true))
  end

  describe 'GET /aeon_activities/:id.csv' do
    it 'sends a CSV attachment named for the activity' do
      get aeon_activity_path(1, format: :csv)

      expect(response.headers['Content-Disposition']).to include('attachment', 'activity-1-an-aeon-activity.csv')
    end

    it 'lists every member request with the requester name' do
      get aeon_activity_path(1, format: :csv)

      rows = CSV.parse(response.body.delete_prefix(AeonActivitiesController::EXCEL_UTF8_BOM), headers: true).map(&:to_h)
      expect(rows).to contain_exactly(
        {
          'Transaction ID' => '307', 'Creation date' => '2024-03-11', 'Requester' => 'Jane Stanford',
          'Title' => 'Throwing a sinker ball at 94 mpg with wicked movement', 'Author' => 'Knuth, Donald',
          'Call number' => 'SC0097', 'Box/Volume' => 'Box 1', 'Date' => '1962-2018', 'FOLIO location' => 'SPEC-STACKS',
          'Item number' => '36105000000000', 'Item URL' => 'https://searchworks.stanford.edu/view/12345678'
        },
        a_hash_including('Transaction ID' => '308', 'Requester' => 'Testing McTesterson')
      )
    end

    it 'orders the rows by transaction number' do
      get aeon_activity_path(1, format: :csv)

      rows = CSV.parse(response.body.delete_prefix(AeonActivitiesController::EXCEL_UTF8_BOM), headers: true)
      expect(rows.pluck('Transaction ID')).to eq %w[307 308]
    end

    it 'starts with a byte order mark so Excel reads the file as UTF-8' do
      get aeon_activity_path(1, format: :csv)

      expect(response.body.dup.force_encoding('UTF-8')).to start_with(AeonActivitiesController::EXCEL_UTF8_BOM)
    end

    it 'is not found for an activity the user is not a member of' do
      get aeon_activity_path(99, format: :csv)

      expect(response).to have_http_status(:not_found)
    end
  end
end
