# frozen_string_literal: true

require 'rails_helper'

describe IlbMailer do
  describe 'ilb_notification' do
    let(:user) { build(:scan_eligible_user) }
    let(:request) { create(:scan, :without_validations, user:) }
    let(:mail) { described_class.ilb_notification(request) }

    describe 'to' do
      it 'is the origin contact email address' do
        expect(mail.to).to eq ['illiad-test@stanford.edu']
      end
    end

    describe 'from' do
      it 'is the configured from address for the origin' do
        expect(mail.from).to eq ['greencirc@stanford.edu']
      end

      describe 'location specific' do
        let(:request) { create(:scan, :without_validations, user:) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['greencirc@stanford.edu']
        end
      end
    end

    describe 'subject' do
      it 'is the default' do
        expect(mail.subject).to eq 'Scan request problem, please remediate'
      end
    end

    describe 'body' do
      let(:request) do
        create(:scan, :without_validations, user:)
      end

      let(:body) { mail.body.to_s }

      it 'has the date' do
        date_str = I18n.l(request.created_at, format: :short)
        expect(body).to include "On #{date_str}, some-eligible-user@stanford.edu requested the following:"
      end

      it 'has the searchworks link' do
        expect(body).to include('https://searchworks.stanford.edu/view/12345')
      end

      it 'has item information' do
        expect(body).to include('Title of article or chapter:')
        expect(body).to include(' Section Title for Scan 12345')
      end

      it 'has a link to the request information' do
        expect(body).to include('https://requests.stanford.edu/scans/1/status')
      end

      it 'has some more information about the user' do
        expect(body).to include('ILLiad Username: some-eligible-user')
      end
    end
  end
end
