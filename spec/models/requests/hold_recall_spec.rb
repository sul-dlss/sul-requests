# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HoldRecall do
  before do
    allow(Settings.ils.bib_model.constantize).to receive(:fetch)
  end

  describe 'requestable' do
    it { is_expected.not_to be_requestable_with_name_email }
    it { is_expected.to be_requestable_with_library_id }
  end

  it 'has the properly assigned Rails STI attribute value' do
    expect(subject.type).to eq 'HoldRecall'
  end

  describe 'send_approval_status!' do
    describe 'for library id users' do
      let(:user) { create(:library_id_user) }
      let(:subject) { create(:hold_recall, user:) }

      before do
        allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: user.library_id).at_least(:once).and_return(
          double(exists?: true, email: nil)
        )
      end

      it 'does not send an approval status email' do
        expect do
          subject.send_approval_status!
        end.not_to have_enqueued_mail
      end
    end

    describe 'for everybody else' do
      let(:subject) { create(:hold_recall, user: create(:sso_user)) }

      it 'sends an approval status email' do
        expect do
          subject.send_approval_status!
        end.to have_enqueued_mail(RequestStatusMailer)
      end
    end
  end

  describe '#submit!' do
    let(:subject) { create(:hold_recall_with_holdings, user:) }
    let(:user) { create(:library_id_user) }
    let(:patron) do
      instance_double(Folio::Patron, exists?: true, email: nil, patron_group_name: 'faculty',
                                     patron_group_id: 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
                                     ilb_eligible?: true)
    end

    before do
      allow(Settings.ils.patron_model.constantize).to receive(:find_by).with(library_id: user.library_id).and_return(patron)
    end

    it 'submits the request to ILLIAD' do
      expect(SubmitIlliadRequestJob).to receive(:perform_later)
      subject.submit!
    end

    context 'when the patron is not eligible to make illiad requests' do
      let(:patron) do
        instance_double(Folio::Patron, exists?: true, email: nil, patron_group_name: 'faculty',
                                       patron_group_id: 'bdc2b6d4-5ceb-4a12-ab46-249b9a68473e',
                                       ilb_eligible?: false)
      end

      it 'submits the request to the ILS' do
        expect(SubmitFolioRequestJob).to receive(:perform_later)
        subject.submit!
      end
    end
  end
end
