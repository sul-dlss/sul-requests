# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetPinsMailer do
  describe '#reset_pin' do
    subject(:mail) { described_class.with(patron:, referrer:).reset_pin }

    let(:patron) do
      instance_double(
        Folio::Patron,
        email: 'jdoe@stanford.edu',
        display_name: 'J Doe',
        library_id: '123',
        pin_reset_token: token
      )
    end
    let(:token) { 'secret_token' }
    let(:referrer) { 'http://example.com' }

    it 'is sent to the patron using their email' do
      expect(mail.to).to eq ['jdoe@stanford.edu']
    end

    it 'is sent from the SUL privileges desk' do
      expect(mail.from).to eq ['sul-privileges@stanford.edu']
    end

    it 'includes a link to the change PIN form in the body' do
      expect(mail.html_part.body).to have_link 'Change my PIN', href: change_pin_with_token_url(token:, referrer:)
    end
  end
end
