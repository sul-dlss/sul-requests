# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe AeonAbility do
  subject { described_class.new(aeon_user) }

  let(:aeon_user) { Aeon::User.new(username: 'testuser@stanford.edu') }
  let(:request) { build(:aeon_request, username: 'testuser@stanford.edu') }

  describe 'an unauthenticated user' do
    let(:aeon_user) { Aeon::NullUser.new }

    it { is_expected.not_to be_able_to(:create, Aeon::Request) }
    it { is_expected.not_to be_able_to(:update, request) }
    it { is_expected.not_to be_able_to(:destroy, request) }
  end

  describe 'an authenticated user' do
    it { is_expected.to be_able_to(:create, Aeon::Request) }
    it { is_expected.to be_able_to(:read, Aeon::Request) }
    it { is_expected.to be_able_to(:manage, Aeon::Appointment) }

    context 'with a draft request they own' do
      before { allow(request).to receive_messages(draft?: true) }

      it { is_expected.to be_able_to(:update, request) }
      it { is_expected.to be_able_to(:destroy, request) }
    end

    context 'with a cancelled request they own' do
      before { allow(request).to receive_messages(draft?: false, cancelled?: true, submitted?: false) }

      it { is_expected.to be_able_to(:update, request) }
    end

    context 'with a submitted request with an editable appointment' do
      before do
        allow(request).to receive_messages(draft?: false, cancelled?: false, submitted?: true)
        allow(request.appointment).to receive_messages(editable?: true)
      end

      it { is_expected.to be_able_to(:update, request) }
    end

    context 'with a submitted request with a non-editable appointment' do
      before do
        allow(request).to receive_messages(draft?: false, cancelled?: false, submitted?: true)
        allow(request.appointment).to receive_messages(editable?: false)
      end

      it { is_expected.not_to be_able_to(:update, request) }
    end

    context 'with a submitted request without an appointment' do
      let(:request) { build(:aeon_request, :without_appointment, username: 'testuser@stanford.edu') }

      before do
        allow(request).to receive_messages(draft?: false, cancelled?: false, submitted?: true)
      end

      it { is_expected.not_to be_able_to(:update, request) }
    end

    context "with another user's request" do
      let(:request) { build(:aeon_request, username: 'otheruser@stanford.edu') }

      before { allow(request).to receive_messages(draft?: true) }

      it { is_expected.not_to be_able_to(:update, request) }
      it { is_expected.not_to be_able_to(:destroy, request) }
    end
  end
end
