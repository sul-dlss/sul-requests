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
    it { is_expected.to be_able_to(:create, Aeon::Appointment) }

    context 'with an editable appointment they own' do
      let(:appointment) { build(:aeon_appointment, username: 'testuser@stanford.edu') }

      before { allow(appointment).to receive(:editable?).and_return(true) }

      it { is_expected.to be_able_to(:read, appointment) }
      it { is_expected.to be_able_to(:update, appointment) }
      it { is_expected.to be_able_to(:destroy, appointment) }
    end

    context 'with a non-editable appointment they own' do
      let(:appointment) { build(:aeon_appointment, username: 'testuser@stanford.edu') }

      before { allow(appointment).to receive(:editable?).and_return(false) }

      it { is_expected.to be_able_to(:read, appointment) }
      it { is_expected.not_to be_able_to(:update, appointment) }
      it { is_expected.to be_able_to(:destroy, appointment) }
    end

    context "with another user's appointment" do
      let(:appointment) { build(:aeon_appointment, username: 'otheruser@stanford.edu') }

      before { allow(appointment).to receive(:editable?).and_return(true) }

      it { is_expected.not_to be_able_to(:read, appointment) }
      it { is_expected.not_to be_able_to(:update, appointment) }
      it { is_expected.not_to be_able_to(:destroy, appointment) }
    end

    context 'with a saved for later request they own' do
      before { allow(request).to receive_messages(saved_for_later?: true) }

      it { is_expected.to be_able_to(:update, request) }
      it { is_expected.to be_able_to(:destroy, request) }
    end

    context 'with a cancelled request they own' do
      before { allow(request).to receive_messages(saved_for_later?: false, cancelled?: true, submitted?: false) }

      it { is_expected.to be_able_to(:update, request) }
    end

    context 'with a submitted request with an editable appointment' do
      before do
        allow(request).to receive_messages(saved_for_later?: false, cancelled?: false, submitted?: true)
        allow(request.appointment).to receive_messages(editable?: true)
      end

      it { is_expected.to be_able_to(:update, request) }
    end

    context 'with a submitted request with a non-editable appointment' do
      before do
        allow(request).to receive_messages(saved_for_later?: false, cancelled?: false, submitted?: true)
        allow(request.appointment).to receive_messages(editable?: false)
      end

      it { is_expected.not_to be_able_to(:update, request) }
    end

    context 'with a submitted request without an appointment' do
      let(:request) { build(:aeon_request, :without_appointment, username: 'testuser@stanford.edu') }

      before do
        allow(request).to receive_messages(saved_for_later?: false, cancelled?: false, submitted?: true)
      end

      it { is_expected.not_to be_able_to(:update, request) }
    end

    context "with another user's request" do
      let(:request) { build(:aeon_request, username: 'otheruser@stanford.edu') }

      before { allow(request).to receive_messages(saved_for_later?: true) }

      it { is_expected.not_to be_able_to(:update, request) }
      it { is_expected.not_to be_able_to(:destroy, request) }
    end

    context "with another user's request attached to an activity the current user belongs to" do
      let(:request) { build(:aeon_request, username: 'otheruser@stanford.edu', activity_id: 42) }
      let(:activity) { build(:aeon_activity, id: 42, users: [Aeon::User.new(username: 'testuser@stanford.edu')]) }

      before do
        allow(request).to receive_messages(saved_for_later?: false, cancelled?: false, activity: activity)
        allow(request.appointment).to receive_messages(editable?: true)
      end

      it { is_expected.to be_able_to(:update, request) }
      it { is_expected.to be_able_to(:destroy, request) }
    end

    context "with another user's request attached to an activity the current user does not belong to" do
      let(:request) { build(:aeon_request, username: 'otheruser@stanford.edu', activity_id: 42) }
      let(:activity) { build(:aeon_activity, id: 42, users: [Aeon::User.new(username: 'someoneelse@stanford.edu')]) }

      before do
        allow(request).to receive_messages(saved_for_later?: true, activity: activity)
      end

      it { is_expected.not_to be_able_to(:update, request) }
      it { is_expected.not_to be_able_to(:destroy, request) }
    end
  end
end
