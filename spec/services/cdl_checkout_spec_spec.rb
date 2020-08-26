# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlCheckout do
  subject { described_class.new('abc123', 'druid', create(:webauth_user)) }

  describe '#process_checkout' do
    it 'places the hold, checks the item out, and creates a token' do
      expect(subject.symphony_client).to receive(:place_hold)
      expect(subject.symphony_client).to receive(:check_out_item).and_return(
        {
          'circRecord' => {
            'fields' => {
              'dueDate' => '2099-08-25T23:59:00-07:00'
            }
          }
        }
      )
      expect(subject.process_checkout).to eq 'eyJhbGciOiJIUzI1NiJ9.eyJiYXJjb2R'\
      'lIjpudWxsLCJhdWQiOiJkcnVpZCIsInN1YiI6InNvbWUtd2ViYXV0aC11c2VyIiwiZXhwIj'\
      'o0MDkxNDEwNzQwfQ.GnSvhnC_cnI0kUAJelPXj5GydJGtZP7OoioFdv9hIpI'
    end
  end
end
