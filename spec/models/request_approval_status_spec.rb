require 'rails_helper'

describe RequestApprovalStatus do
  let(:request) { create(:request) }
  subject { described_class.new(request: request) }

  describe 'pending' do
    let(:request) { create(:request_with_holdings) }

    it 'is true when the there is no symphony response data present' do
      expect(subject).to be_pending
    end

    describe 'status html and text' do
      let(:html) { Capybara.string(subject.to_html) }
      let(:text) { subject.to_text }

      context 'by default' do
        it 'is the default text' do
          expect(html).to have_css('dd', text: 'Pending.')
          expect(text).to eq 'Pending. '
        end
      end

      context 'for mediated pages' do
        let(:request) { create(:page_mp_mediated_page) }

        it 'is the mediated page text' do
          expect(html).to have_css('dd', text: 'Waiting for approval.')
          expect(text).to eq 'Waiting for approval. '
        end
      end

      context 'for origins that include additional pending text' do
        let(:request) { create(:mediated_page, origin: 'SPEC-COLL') }

        it 'the extra text is included' do
          expect(html).to have_css(
            'dd',
            text: 'Waiting for approval. Items are typically approved 1-3 days before your scheduled visit.'
          )
          expect(text).to eq 'Waiting for approval. Items are typically approved 1-3 days before your scheduled visit.'
        end
      end
    end
  end

  describe 'individual item approval status' do
    let(:html) { Capybara.string(subject.to_html) }
    let(:text) { subject.to_text }
    describe 'status html' do
      context 'success' do
        let(:request) { create(:request_with_holdings, barcodes: ['12345678']) }
        before do
          stub_symphony_response(build(:symphony_page_with_multiple_items))
        end

        context 'by default' do
          it 'is the default success text' do
            expect(html).to have_css('dd', text: 'ABC 123 has been paged for delivery.')
            expect(text).to eq 'ABC 123 has been paged for delivery.'
          end
        end

        context 'when there is a request specific success label' do
          let(:request) { create(:mediated_page_with_holdings, barcodes: ['12345678']) }

          it 'returns the request type specific success label' do
            expect(html).to have_css('dd', text: 'ABC 123 has been approved.')
            expect(text).to eq 'ABC 123 has been approved.'
          end
        end
      end

      context 'error' do
        let(:request) { create(:mediated_page_with_holdings, barcodes: ['23456789']) }
        before { stub_symphony_response(build(:symphony_request_with_mixed_status)) }

        it 'includes the error text returned from symphony' do
          expect(html).to have_css('dd.approval-error', text: 'Attention: ABC 456 Item not found in catalog')
          expect(text).to eq 'Attention: ABC 456 Item not found in catalog'
        end
      end
    end
  end

  describe 'user error' do
    let(:request) { create(:request_with_holdings) }
    let(:html) { Capybara.string(subject.to_html) }
    let(:text) { subject.to_text }
    before do
      stub_symphony_response(build(:symphony_page_with_expired_user))
    end

    it 'returns a status message indicating the user error' do
      expect(html).to have_css('dd', text: "We can't complete your request because your privileges have expired.")
      expect(html).to have_link('Check MyAccount for details.')
    end

    it 'returns nothing for user error text because that is handled elsewhere in the plan-text context' do
      expect(text).to be_blank
    end

    it 'returns a default message if we receive an unknown user error code' do
      expect(request.symphony_response).to receive(:usererr_code).at_least(:once).and_return('unknown-code')
      expect(html).to have_css('dd', text: 'We were unable to process your request because of a system error.')
      expect(html).to have_css('dd', text: 'Please try again, or contact greencirc@stanford.edu for more assistance.')
      expect(html).to have_link('greencirc@stanford.edu')
    end
  end
end
