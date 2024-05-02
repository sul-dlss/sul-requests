# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability do
  subject { described_class.new(user, token) }

  let(:admin_comment) { AdminComment.new(request:) }
  let(:request) { Request.new }
  let(:hold_recall) { HoldRecall.new }
  let(:mediated_page) { MediatedPage.new }
  let(:page) { Page.new }
  let(:scan) { Scan.new }
  let(:request_objects) { [hold_recall, mediated_page, page, scan] }
  let(:message) { Message.new }
  let(:token) { nil }

  describe 'site admins' do
    let(:user) { create(:site_admin_user) }

    it { is_expected.to be_able_to(:manage, LibraryLocation) }
    it { is_expected.to be_able_to(:manage, Message) }
    it { is_expected.to be_able_to(:manage, PagingSchedule) }
    it { is_expected.to be_able_to(:manage, Request) }
    it { is_expected.to be_able_to(:debug, Request) }
  end

  describe 'an anonymous user' do
    let(:user) { create(:anon_user) }

    it { is_expected.to be_able_to(:new, hold_recall) }
    it { is_expected.not_to be_able_to(:create, hold_recall) }
    it { is_expected.not_to be_able_to(:read, hold_recall) }
    it { is_expected.not_to be_able_to(:update, hold_recall) }
    it { is_expected.not_to be_able_to(:delete, hold_recall) }
    it { is_expected.not_to be_able_to(:success, hold_recall) }
    it { is_expected.not_to be_able_to(:status, hold_recall) }

    it { is_expected.to be_able_to(:new, mediated_page) }
    it { is_expected.not_to be_able_to(:create, mediated_page) }
    it { is_expected.not_to be_able_to(:read, mediated_page) }
    it { is_expected.not_to be_able_to(:update, mediated_page) }
    it { is_expected.not_to be_able_to(:delete, mediated_page) }
    it { is_expected.not_to be_able_to(:success, mediated_page) }
    it { is_expected.not_to be_able_to(:status, mediated_page) }

    it { is_expected.to be_able_to(:new, page) }
    it { is_expected.not_to be_able_to(:create, page) }
    it { is_expected.not_to be_able_to(:read, page) }
    it { is_expected.not_to be_able_to(:update, page) }
    it { is_expected.not_to be_able_to(:delete, page) }
    it { is_expected.not_to be_able_to(:success, page) }
    it { is_expected.not_to be_able_to(:success, page) }
    it { is_expected.not_to be_able_to(:status, page) }

    it { is_expected.to be_able_to(:new, scan) }
    it { is_expected.not_to be_able_to(:create, scan) }
    it { is_expected.not_to be_able_to(:read, scan) }
    it { is_expected.not_to be_able_to(:update, scan) }
    it { is_expected.not_to be_able_to(:delete, scan) }
    it { is_expected.not_to be_able_to(:success, scan) }
    it { is_expected.not_to be_able_to(:status, scan) }

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

    describe 'who fills out a name and email' do
      let(:user) { build(:non_sso_user) }
      let(:page) { build(:page, user:) }
      let(:mediated_page) { build(:mediated_page, user:) }

      it { is_expected.to be_able_to(:create, page) }
      it { is_expected.to be_able_to(:create, mediated_page) }

      describe 'and views a success page with a token' do
        before do
          allow(Settings.ils.bib_model.constantize).to receive(:fetch).and_return(double(:bib_data, title: 'Test title',
                                                                                                    request_holdings: []))
        end

        describe 'for a page' do
          before do
            page.save!
          end

          let(:token) { page.encrypted_token }

          it { is_expected.to be_able_to(:success, page) }
        end

        describe 'for a mediated page' do
          before do
            mediated_page.save!
          end

          let(:token) { mediated_page.encrypted_token }

          it { is_expected.to be_able_to(:success, mediated_page) }
        end
      end
    end

    describe 'who fills out the library ID field' do
      let(:user) { build(:library_id_user) }
      let(:page) { build(:page, user:) }
      let(:mediated_page) { build(:mediated_page, user:) }
      let(:scan) { build(:scan, :without_validations, user:) }

      it { is_expected.to be_able_to(:create, page) }
      it { is_expected.to be_able_to(:create, mediated_page) }
      it { is_expected.to be_able_to(:create, mediated_page) }
    end
  end

  describe 'a SSO user' do
    let(:user) { create(:sso_user) }

    it { is_expected.to be_able_to(:create, hold_recall) }
    it { is_expected.to be_able_to(:create, mediated_page) }
    it { is_expected.to be_able_to(:create, page) }
    it { is_expected.not_to be_able_to(:create, scan) }
    it { is_expected.not_to be_able_to(:debug, page) }

    describe 'who created the request' do
      before do
        request_objects.each do |object|
          allow(object).to receive_messages(user_id: user.id)
        end
      end

      # Can see the success page for their request
      it { is_expected.to be_able_to(:success, hold_recall) }
      it { is_expected.to be_able_to(:success, mediated_page) }
      it { is_expected.to be_able_to(:success, page) }
      it { is_expected.to be_able_to(:success, scan) }

      # Can see the status page for their request
      it { is_expected.to be_able_to(:status, hold_recall) }
      it { is_expected.to be_able_to(:status, mediated_page) }
      it { is_expected.to be_able_to(:status, page) }
      it { is_expected.to be_able_to(:status, scan) }
    end

    context 'with a request for an item that is not requestable by non-affiliates' do
      let(:request) { PatronRequest.new(instance_hrid: 'a1234', origin_location_code: 'LAW-STACKS1') }
      let(:patron) do
        instance_double(Folio::Patron, id: '', patron_group_id: '3684a786-6671-4268-8ed0-9db82ebca60b',
                                       patron_group_name: 'staff', allowed_request_types: ['Page'])
      end

      before do
        allow(user).to receive(:patron).and_return(patron)
        allow(request).to receive(:bib_data).and_return(build(:single_holding,
                                                              items: [build(:item, effective_location: build(:law_location))]))
      end

      it { is_expected.to be_able_to(:prepare, request) }
    end

    describe 'who did not create the requst' do
      before do
        request_objects.each do |object|
          allow(object).to receive_messages(user_id: User.create(sunetid: 'some-other-user').id)
        end
      end

      # Can't see the success page for other user's requests
      it { is_expected.not_to be_able_to(:success, hold_recall) }
      it { is_expected.not_to be_able_to(:success, mediated_page) }
      it { is_expected.not_to be_able_to(:success, page) }
      it { is_expected.not_to be_able_to(:success, scan) }

      # Can't see the status page for other user's requests
      it { is_expected.not_to be_able_to(:status, hold_recall) }
      it { is_expected.not_to be_able_to(:status, mediated_page) }
      it { is_expected.not_to be_able_to(:status, page) }
      it { is_expected.not_to be_able_to(:status, scan) }
    end

    describe 'who is in the scan and deliver pilot group' do
      let(:user) { create(:scan_eligible_user) }
      let(:patron) { build(:pilot_group_patron) }

      before do
        allow(user).to receive(:patron).and_return(patron)
      end

      it { is_expected.to be_able_to(:create, scan) }
    end

    describe 'who is a student' do
      let(:patron) { build(:student_patron) }

      before do
        allow(user).to receive(:patron).and_return(patron)
      end

      it { is_expected.to be_able_to(:create, scan) }
    end
  end

  describe 'a super admin' do
    let(:user) { create(:superadmin_user) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
    it { is_expected.to be_able_to(:create, admin_comment) }
  end

  describe 'a site admin' do
    let(:user) { create(:site_admin_user) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }

    it { is_expected.to be_able_to(:new, message) }
    it { is_expected.to be_able_to(:create, message) }
    it { is_expected.to be_able_to(:read, message) }
    it { is_expected.to be_able_to(:update, message) }
    it { is_expected.to be_able_to(:delete, message) }
    it { is_expected.to be_able_to(:create, admin_comment) }
  end

  describe 'an origin library admin' do
    let(:user) { create(:art_origin_admin_user) }

    before do
      request.origin = 'ART'
      hold_recall.origin = 'ART'
      mediated_page.origin = 'ART'
      page.origin = 'ART'
      scan.origin = 'ART'
    end

    # can manage libraries that they are an admin of
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }

    it { is_expected.not_to be_able_to(:new, message) }
    it { is_expected.not_to be_able_to(:create, message) }
    it { is_expected.not_to be_able_to(:read, message) }
    it { is_expected.not_to be_able_to(:update, message) }
    it { is_expected.not_to be_able_to(:delete, message) }

    it { is_expected.to be_able_to(:create, admin_comment) }
  end

  describe 'an origin location admin' do
    let(:user) { create(:page_mp_origin_admin_user) }

    before do
      request.origin_location = 'SAL3-PAGE-MP'
      hold_recall.origin_location = 'SAL3-PAGE-MP'
      mediated_page.origin_location = 'SAL3-PAGE-MP'
      page.origin_location = 'SAL3-PAGE-MP'
      scan.origin_location = 'SAL3-PAGE-MP'
    end

    # can manage locations that they are an admin of
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
    it { is_expected.to be_able_to(:create, admin_comment) }
  end
end
