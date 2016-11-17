require 'rails_helper'

describe ApprovalStatusMailer do
  describe '#request_approval_status' do
    let(:user) { build(:non_webauth_user) }
    let(:request) { create(:page, user: user) }
    let(:mail) { ApprovalStatusMailer.request_approval_status(request) }

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
          expect(mail.subject).to eq "Your request has been processed (\"#{request.item_title}\")"
        end
      end
      describe 'failure' do
        before do
          allow(request.symphony_response).to receive(:success?).and_return false
        end
        it '"Attention needed ... request could not be processed"' do
          fail_mail = ApprovalStatusMailer.request_approval_status(request)
          expect(fail_mail.subject).to eq "Attention needed: Your request could not be processed (\"#{request.item_title}\")"
        end
      end
      describe 'user blocked' do
        let(:blocked_request) { create(:page_with_holdings, barcodes: ['3610512345678'], user: user) }
        let(:blocked_mail) { ApprovalStatusMailer.request_approval_status(blocked_request) }
        before do
          stub_symphony_response(build(:symphony_page_with_blocked_user))
        end
        it '"Attention needed ... request could not be processed"' do
          expect(blocked_mail.subject).to eq "Attention needed: Your request could not be processed (\"#{blocked_request.item_title}\")"
        end
      end
    end

    describe 'body' do
      before do
        allow(request.symphony_response).to receive(:success?).and_return true
      end
      let(:request) { create(:page_with_holdings, barcodes: ['3610512345678'], ad_hoc_items: ['ZZZ 123'], user: user) }
      let(:body) { mail.body.to_s }
      it 'has the date' do
        expect(body).to match(/On #{request.created_at.strftime('%A, %b %-d %Y')}, you requested:/)
      end

      it 'has the title' do
        expect(body).to include(request.item_title)
      end

      it 'has items processed' do
        expect(body).to include('ABC 123')
      end

      it 'has ad hoc items' do
        expect(body).to include('ZZZ 123')
      end

      describe 'success' do
        it 'has items processed line' do
          expect(body).to include('The items listed below have been processed:')
        end

        it 'has a not needed after date if present' do
          my_request = create(:page, needed_date: '2066-06-06', user: user)
          mailer = ApprovalStatusMailer.request_approval_status(my_request)
          h = my_request.class.human_attribute_name(:needed_date)
          expect(mailer.body.to_s).to include "#{h}: #{I18n.l my_request.needed_date, format: :long}"
        end

        it 'has a link to the status page' do
          expect(body).to match(%r{Any further updates will be posted on the status page at .*\/pages\/#{request.id}\/status\?token})
        end

        it 'does not have scan suggestion' do
          expect(body).not_to include 'Even though your status is blocked, you are eligible for Scan to PDF.'
        end

        context 'with a webauth user' do
          let(:user) { build(:webauth_user) }

          it 'has a link to myaccount' do
            expect(body).to include 'You can also see the status at http://library.stanford.edu/myaccount'
          end
        end
      end

      describe 'failure' do
        before do
          allow(request.symphony_response).to receive(:success?).and_return false
          request = create(:page_with_holdings, barcodes: ['3610512345678'], user: user)
          fail_mail = ApprovalStatusMailer.request_approval_status(request)
          @fail_body = fail_mail.body.to_s
        end
        it 'has item status line' do
          expect(@fail_body).to include('There were problems with one or more of the items listed below:')
        end

        it 'has what can you do now section' do
          expect(@fail_body).to include 'What can you do now?'
          expect(@fail_body).to include 'Request assistance by replying to this email, or'
        end

        describe 'user not blocked' do
          it 'has searchworks link' do
            sw_url = "https://searchworks.stanford.edu/view/#{request.id}"
            expect(@fail_body).to include "try your request again, at #{sw_url}"
          end
          it 'does not have scan suggestion' do
            expect(@fail_body).not_to include 'Even though your status is blocked, you are eligible for Scan to PDF.'
          end
        end

        describe 'user blocked' do
          let(:blocked_request) { create(:page_with_holdings, barcodes: ['3610512345678'], user: user) }
          let(:blocked_mail) { ApprovalStatusMailer.request_approval_status(blocked_request) }
          let(:blocked_body) { blocked_mail.body.to_s }
          before do
            stub_symphony_response(build(:symphony_page_with_blocked_user))
          end
          it 'has item header line' do
            expect(blocked_body).to include('Items:')
          end
          it 'has item status line' do
            expect(blocked_body).to include('Your request could not be processed because your user privileges are blocked.')
          end
          it 'has myaccount link' do
            line = 'check MyAccount (http://library.stanford.edu/myaccount) for more information.'
            expect(blocked_body).to include line
          end
          it 'has scan suggestion' do
            expect(blocked_body).to include 'Just need a chapter or article?'
            expect(blocked_body).to include 'Even though your status is blocked, you are eligible for Scan to PDF.'
            expect(blocked_body).to include 'You can request a single article or chapter, up to 50 pages.'
            expect(blocked_body).to include "https://searchworks.stanford.edu/view/#{blocked_request.item_id}"
          end
        end
        describe 'user expired' do
          let(:expired_request) { create(:page_with_holdings, barcodes: ['3610512345678'], user: user) }
          let(:expired_mail) { ApprovalStatusMailer.request_approval_status(expired_request) }
          let(:expired_body) { expired_mail.body.to_s }
          before do
            stub_symphony_response(build(:symphony_page_with_expired_user))
          end
          it 'has item status line' do
            expect(expired_body).to include('Your request could not be processed because your user privileges have expired.')
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
    end
  end
end
