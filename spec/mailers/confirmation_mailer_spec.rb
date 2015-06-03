require 'rails_helper'

describe ConfirmationMailer do
  describe 'request_confirmation' do
    let(:user) { build(:non_webauth_user) }
    let(:request) { create(:page, user: user) }
    let(:mail) { ConfirmationMailer.request_confirmation(request) }

    describe 'to' do
      it 'is the user email address' do
        expect(mail.to).to eq ['jstanford@stanford.edu']
      end
    end

    describe 'from' do
      it 'is the default' do
        expect(mail.from).to eq ['greencirc@stanford.edu']
      end
    end

    describe 'subject' do
      describe 'for Scan requests' do
        let(:request) { create(:scan_with_holdings, user: user) }
        it 'is custom' do
          expect(mail.subject).to eq "Scan to PDF requested (#{request.item_title})"
        end
      end

      describe 'for other requests' do
        it 'is the default' do
          expect(mail.subject).to eq "Item(s) requested (#{request.item_title})"
        end
      end
    end

    describe 'body' do
      let(:request) { create(:page_with_holdings, barcodes: ['12345678'], user: user) }
      let(:body) { mail.body.to_s }
      it 'has the date' do
        expect(body).to match(/On #{request.created_at.strftime('%A, %b %-d %Y')}, you requested the following:/)
      end

      it 'has the title' do
        expect(body).to include(request.item_title)
      end

      it 'has holdings information' do
        expect(body).to include('Item(s) requested:')
        expect(body).to include('ABC 123')
      end

      it 'has a link to the status page' do
        expect(body).to match(%r{Check the status of your request at .*\/pages\/#{request.id}\/status\?token})
      end

      it 'has contact information' do
        expect(body).to include('Questions about your request?')
        expect(body).to include('Contact:')
        expect(body).to match(/\(\d{3}\) \d{3}-\d{4}/)
        expect(body).to include('greencirc@stanford.edu')
      end
    end
  end
end
