# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  subject { described_class.new(user) }

  let(:request) { PatronRequest.new(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1') }

  let(:admin_comment) { AdminComment.new(request:) }
  let(:message) { Message.new }

  describe 'site admins' do
    let(:user) { create(:site_admin_user) }

    it { is_expected.to be_able_to(:manage, LibraryLocation) }
    it { is_expected.to be_able_to(:manage, Message) }
    it { is_expected.to be_able_to(:manage, PagingSchedule) }
  end

  describe 'an anonymous user' do
    let(:user) { create(:anon_user) }

    it { is_expected.not_to be_able_to(:new, message) }
    it { is_expected.not_to be_able_to(:create, message) }
    it { is_expected.not_to be_able_to(:read, message) }
    it { is_expected.not_to be_able_to(:update, message) }
    it { is_expected.not_to be_able_to(:delete, message) }

    it { is_expected.not_to be_able_to(:create, admin_comment) }

    context 'with a request for an item that is not requestable by non-affiliates' do
      let(:request) { PatronRequest.new(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1') }

      before do
        allow(request).to receive(:bib_data).and_return(build(:single_holding,
                                                              items: [build(:item, effective_location: build(:law_location))]))
      end

      it { is_expected.not_to be_able_to(:prepare, request) }
    end
  end

  describe 'a SSO user' do
    let(:user) { create(:sso_user) }

    context 'with a request for an item that is not requestable by non-affiliates' do
      let(:request) { PatronRequest.new(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1') }
      let(:patron) do
        instance_double(Folio::Patron, id: '', patron_group_name: 'staff', allowed_request_types: ['Page'])
      end

      before do
        allow(user).to receive(:patron).and_return(patron)
        allow(request).to receive(:bib_data).and_return(build(:single_holding,
                                                              items: [build(:item, effective_location: build(:law_location))]))
      end

      it { is_expected.to be_able_to(:new, request) }
    end
  end

  describe 'a super admin' do
    let(:user) { create(:superadmin_user) }

    # can manage anything
    it { is_expected.to be_able_to(:create, admin_comment) }
  end

  describe 'a site admin' do
    let(:user) { create(:site_admin_user) }

    # can manage anything

    it { is_expected.to be_able_to(:new, message) }
    it { is_expected.to be_able_to(:create, message) }
    it { is_expected.to be_able_to(:read, message) }
    it { is_expected.to be_able_to(:update, message) }
    it { is_expected.to be_able_to(:delete, message) }
    it { is_expected.to be_able_to(:create, admin_comment) }
  end

  describe 'an origin library admin' do
    let(:user) { create(:art_origin_admin_user) }

    # can manage libraries that they are an admin of
    it { is_expected.not_to be_able_to(:new, message) }
    it { is_expected.not_to be_able_to(:create, message) }
    it { is_expected.not_to be_able_to(:read, message) }
    it { is_expected.not_to be_able_to(:update, message) }
    it { is_expected.not_to be_able_to(:delete, message) }
  end
end
