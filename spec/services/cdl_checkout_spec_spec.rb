# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CdlCheckout do
  subject { described_class.new('abc123', 'druid', user) }
  let(:user) { create(:webauth_user) }

  before do
    allow(user).to receive(:patron).and_return(Patron.new({}))
  end

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

      token = subject.process_checkout

      payload, _headers = JWT.decode(token, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)

      expect(payload.with_indifferent_access).to include sub: user.webauth
    end
  end
end
