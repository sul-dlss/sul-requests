# frozen_string_literal: true

require 'rails_helper'

describe RequestStatusMailer do
  describe '#request_status' do
    let(:user) { build(:non_sso_user) }
    let(:request) { create(:page, user:) }
    let(:mailer_method) { :request_status_for_page }
    let(:mail) { described_class.send(mailer_method, request) }

    describe '#request_status_for_u003' do
      let(:mailer_method) { :request_status_for_u003 }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          'We were unable to process your request because your status is BLOCKED.'
        )
      end

      describe '#request_status_for_u004' do
        let(:mailer_method) { :request_status_for_u004 }

        it 'renders the correct email' do
          expect(mail.body.to_s).to include(
            'We were unable to process your request because your status is EXPIRED.'
          )
        end
      end

      describe '#generic_ils_error' do
        let(:mailer_method) { :generic_ils_error }

        it 'renders the correct email' do
          expect(mail.body.to_s).to include(
            'Something went wrong and we were unable to process your request'
          )
        end
      end

      context 'when the item is scannable' do
        let(:request) { create(:scan, :with_holdings_barcodes, user:) }

        it 'indicates to the user they can request the item be scanned' do
          expect(mail.body.to_s).to include(
            'Even though your status is blocked, you are eligible for Scan to PDF.'
          )
        end
      end
    end

    describe '#request_status_for_holdrecall' do
      let(:mailer_method) { :request_status_for_holdrecall }
      let(:request) { create(:hold_recall, user:) }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          'You have been added to the hold queue for the following item(s):'
        )
      end
    end

    describe '#request_status_for_page' do
      let(:request) { create(:page, user:) }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          "We've received your request. We'll email you again when it's ready for pickup."
        )
      end
    end

    describe '#request_status_for_scan' do
      let(:mailer_method) { :request_status_for_scan }
      let(:request) { create(:scan, :without_validations, user:, page_range: '1-2', section_title: 'Chapter2') }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          "We'll email you again when your request is ready for download."
        )
      end

      it 'delimits request data with HTML safe line breaks' do
        expect(mail.body.to_s).not_to include(
          '&lt;br/&gt;'
        )
      end
    end

    describe '#request_status_from_mediatedpage' do
      let(:mailer_method) { :request_status_for_mediatedpage }

      describe 'from' do
        describe 'origin specific' do
          let(:request) { create(:mediated_page, user:) }

          it 'is the configured from address for the origin' do
            expect(mail.from).to eq ['artlibrary@stanford.edu']
          end
        end

        describe 'location specific' do
          let(:request) { create(:page_mp_mediated_page, user:) }

          it 'is the configured from address for the origin' do
            expect(mail.from).to eq ['brannerlibrary@stanford.edu']
          end
        end
      end

      describe 'subject' do
        let(:request) { create(:page_mp_mediated_page, user:) }

        it 'is the default' do
          expect(mail.subject).to eq "Request is pending approval (\"#{request.item_title}\")"
        end
      end

      describe 'body' do
        let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:) }
        let(:body) { mail.body.to_s }

        it 'has the title' do
          expect(body).to include("Title: #{request.item_title}")
        end

        it 'has holdings information' do
          expect(body).to include('Item(s) requested:')
          expect(body).to include('ABC 123')
        end

        context 'for a mediated page' do
          let(:request) do
            create(:mediated_page_with_holdings, barcodes: ['12345678'], user:)
          end

          it 'has a planned date of visit' do
            expect(body).to include 'Items approved for access will be ready when you visit'
            expect(body).to include I18n.l request.needed_date, format: :long
          end
        end

        it 'has a link to the status page' do
          expect(body).to match(%r{Check the status before your visit at .*/pages/#{request.id}/status\?token})
        end
      end
    end

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
        let(:request) { create(:scan, :without_validations, user:) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['scan-and-deliver@stanford.edu']
        end
      end

      describe 'origin specific' do
        let(:request) { create(:mediated_page, user:) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['artlibrary@stanford.edu']
        end
      end

      describe 'location specific' do
        let(:request) { create(:page_mp_mediated_page, user:) }

        it 'is the configured from address for the origin' do
          expect(mail.from).to eq ['brannerlibrary@stanford.edu']
        end
      end

      describe 'for generic errors' do
        let(:mailer_method) { :generic_ils_error }

        it 'has a custom from address' do
          expect(mail.from).to eq ['sul-requests-support@stanford.edu']
        end
      end
    end

    describe 'subject' do
      describe 'success' do
        it '"request has been processed"' do
          expect(mail.subject).to eq "We received your request for \"#{request.item_title}\""
        end
      end

      describe 'failure' do
        before do
          allow(request.ils_response).to receive(:all_successful?).and_return false
        end

        it '"Attention needed ... problem with your request"' do
          expect(mail.subject).to eq "Attention needed: There is a problem with your request (\"#{request.item_title}\")"
        end
      end

      describe 'user blocked' do
        let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user:) }

        before do
          stub_symphony_response(build(:symphony_page_with_blocked_user))
        end

        it '"Attention needed ... problem with your request"' do
          expect(mail.subject).to eq "Attention needed: There is a problem with your request (\"#{request.item_title}\")"
        end
      end
    end

    # TODO: COVID-19 Not linking to the status page for now
    pending 'status url' do
      let(:body) { Capybara.string(mail.body.to_s) }

      it 'gives the correct URL w/ an https protocol' do
        expect(body).to have_css('p', text: 'You can see this request status online at requests.stanford.edu')
        expect(body).to have_link('requests.stanford.edu', href: %r{^https://example\.com/pages/1/status})
      end
    end

    describe 'contact info' do
      let(:body) { mail.body.to_s }

      describe 'default' do
        let(:request) { create(:page_with_holdings, user:) }

        it 'includes the configured contact information' do
          expect(body).to include('Questions about your request?')
          expect(body).to include('Contact:')
          expect(body).to match(/\(\d{3}\) \d{3}-\d{4}/)
          expect(body).to include('greencirc@stanford.edu')
        end
      end
    end
  end
end
