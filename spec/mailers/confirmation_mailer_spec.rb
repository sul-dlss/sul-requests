# frozen_string_literal: true

require 'rails_helper'

describe ConfirmationMailer do
  describe 'request_confirmation' do
    let(:user) { build(:non_webauth_user) }
    let(:request) { create(:page, user: user) }
    let(:mail) { described_class.request_confirmation(request) }

    describe 'to' do
      it 'is the user email address' do
        expect(mail.to).to eq ['jstanford@stanford.edu']
      end
    end

    describe 'from' do
      describe 'default' do
        it 'is the configured default' do
          expect(mail.from).to eq ['greencirc@stanford.edu']
        end
      end

      describe 'destination specific' do
        let(:request) { create(:scan, user: user) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['scan-and-deliver@stanford.edu']
        end
      end

      describe 'origin specific' do
        let(:request) { create(:mediated_page, user: user) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['specialcollections@stanford.edu']
        end
      end

      describe 'location specific' do
        let(:request) { create(:page_mp_mediated_page, user: user) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['brannerlibrary@stanford.edu']
        end
      end
    end

    describe 'subject' do
      describe 'for Scan requests' do
        let(:request) { create(:scan_with_holdings, user: user) }

        it 'is custom' do
          expect(mail.subject).to eq "Scan to PDF requested (\"#{request.item_title}\")"
        end
      end

      describe 'for mediated pages from SPEC-COLL' do
        let(:request) { create(:mediated_page, origin: 'SPEC-COLL', user: user) }

        it 'is custom' do
          expect(mail.subject).to eq "Request received: \"#{request.item_title}\""
        end
      end

      describe 'for other requests' do
        it 'is the default' do
          expect(mail.subject).to eq "Request is pending approval (\"#{request.item_title}\")"
        end
      end
    end

    describe 'body' do
      let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], ad_hoc_items: ['ZZZ 123'], user: user) }
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

      it 'has ad hoc items' do
        expect(body).to include('ZZZ 123')
      end

      context 'for a mediated page' do
        let(:request) do
          create(:mediated_page_with_holdings, barcodes: ['12345678'], ad_hoc_items: ['ZZZ 123'], user: user)
        end

        it 'has a planned date of visit' do
          expect(body).to include 'Items approved for access will be ready when you visit'
          expect(body).to include I18n.l request.needed_date, format: :long
        end
      end

      it 'has a link to the status page' do
        expect(body).to match(%r{Check the status of your request at .*\/pages\/#{request.id}\/status\?token})
      end

      context 'with a webauth user' do
        let(:user) { build(:webauth_user) }

        context 'for a scan request' do
          let(:request) { create(:scan_with_holdings, user: user) }

          it 'excludes the myaccount link for a scan request' do
            expect(body).not_to include 'You can also see the status at http://library.stanford.edu/myaccount'
          end
        end
      end
    end

    describe 'contact info' do
      let(:body) { mail.body.to_s }

      describe 'default' do
        let(:request) { create(:page_with_holdings, user: user) }

        it 'includes the configured contact information' do
          expect(body).to include('Questions about your request?')
          expect(body).to include('Contact:')
          expect(body).to match(/\(\d{3}\) \d{3}-\d{4}/)
          expect(body).to include('greencirc@stanford.edu')
        end
      end

      describe 'origin specific' do
        let(:request) { create(:mediated_page, user: user) }

        it 'includes the configured contact information' do
          expect(body).to include('specialcollections@stanford.edu')
        end
      end

      describe 'location specific' do
        let(:request) { create(:page_mp_mediated_page, user: user) }

        it 'includes the configured contact information' do
          expect(body).to include('brannerlibrary@stanford.edu')
        end
      end
    end
  end
end
