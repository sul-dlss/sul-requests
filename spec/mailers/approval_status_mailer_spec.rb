require 'rails_helper'

describe ApprovalStatusMailer do
  describe '#request_approval_status' do
    let(:user) { build(:non_webauth_user) }
    let(:request) { create(:page, user: user) }
    let(:mailer_method) { :approval_status_for_page }
    let(:mail) { ApprovalStatusMailer.send(mailer_method, request) }

    describe '#approval_status_for_u002' do
      let(:mailer_method) { :approval_status_for_u002 }
      before { user.library_id = 'ABC123' }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          'Stanford Library ID you entered (ABC123) was not found in our system'
        )
      end
    end

    describe '#approval_status_for_u003' do
      let(:mailer_method) { :approval_status_for_u003 }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          'We were unable to process your request because your status is BLOCKED.'
        )
      end

      describe '#approval_status_for_u004' do
        let(:mailer_method) { :approval_status_for_u004 }

        it 'renders the correct email' do
          expect(mail.body.to_s).to include(
            'We were unable to process your request because your status is EXPIRED.'
          )
        end
      end

      context 'when the item is scannable' do
        let(:request) { create(:scan_with_holdings_barcodes, user: user) }

        it 'indicates to the user they can request the item be scanned' do
          expect(mail.body.to_s).to include(
            'Even though your status is blocked, you are eligible for Scan to PDF.'
          )
        end
      end
    end

    describe '#approval_status_for_holdrecall' do
      let(:mailer_method) { :approval_status_for_holdrecall }
      let(:request) { create(:hold_recall, user: user) }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          'You have been added to the hold queue for the following item(s):'
        )
      end
    end

    describe '#approval_status_for_page' do
      let(:request) { create(:page, user: user) }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          "You'll receive another email when your request is ready for pickup."
        )
      end
    end

    describe '#approval_status_for_scan' do
      let(:mailer_method) { :approval_status_for_scan }
      let(:request) { create(:scan, user: user) }

      it 'renders the correct email' do
        expect(mail.body.to_s).to include(
          "You'll receive another email when your request is ready for download."
        )
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
      describe 'success' do
        it '"request has been processed"' do
          expect(mail.subject).to eq "Request received: \"#{request.item_title}\""
        end
      end
      describe 'failure' do
        before do
          allow(request.symphony_response).to receive(:success?).and_return false
        end
        it '"Attention needed ... request could not be processed"' do
          expect(mail.subject).to eq "Attention needed: Your request could not be processed (\"#{request.item_title}\")"
        end
      end
      describe 'user blocked' do
        let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], user: user) }
        before do
          stub_symphony_response(build(:symphony_page_with_blocked_user))
        end
        it '"Attention needed ... request could not be processed"' do
          expect(mail.subject).to eq "Attention needed: Your request could not be processed (\"#{request.item_title}\")"
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
    end
  end
end
