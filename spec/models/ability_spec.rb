require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:request) { Request.new }
  let(:custom) { Custom.new }
  let(:hold_recall) { HoldRecall.new }
  let(:mediated_page) { MediatedPage.new }
  let(:page) { Page.new }
  let(:scan) { Scan.new }
  let(:request_objects) { [custom, hold_recall, mediated_page, page, scan] }
  let(:message) { Message.new }
  let(:token) { nil }
  subject { Ability.new(user, token) }

  describe 'site admins' do
    let(:user) { create(:site_admin_user) }

    it { is_expected.to be_able_to(:manage, LibraryLocation) }
    it { is_expected.to be_able_to(:manage, Message) }
    it { is_expected.to be_able_to(:manage, PagingSchedule) }
    it { is_expected.to be_able_to(:manage, Request) }
  end

  describe 'an anonymous user' do
    let(:user) { create(:anon_user) }

    it { is_expected.to be_able_to(:new, custom) }
    it { is_expected.not_to be_able_to(:create, custom) }
    it { is_expected.not_to be_able_to(:read, custom) }
    it { is_expected.not_to be_able_to(:update, custom) }
    it { is_expected.not_to be_able_to(:delete, custom) }
    it { is_expected.not_to be_able_to(:success, custom) }
    it { is_expected.not_to be_able_to(:status, custom) }

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

    describe 'who fills out a name and email' do
      let(:user) { build(:non_webauth_user) }
      let(:page) { build(:page, user: user) }
      let(:mediated_page) { build(:mediated_page, user: user) }
      it { is_expected.to be_able_to(:create, page) }
      it { is_expected.to be_able_to(:create, mediated_page) }
      describe 'and views a success page with a token' do
        describe 'for a page' do
          let(:token) { page.encrypted_token }
          it { is_expected.to be_able_to(:success, page) }
        end
        describe 'for a mediated page' do
          let(:token) { mediated_page.encrypted_token }
          it { is_expected.to be_able_to(:success, mediated_page) }
        end
      end
      describe 'when the library is HOPKINS' do
        before { mediated_page.origin = 'HOPKINS' }
        it { is_expected.not_to be_able_to(:create, mediated_page) }
      end
    end

    describe 'who fills out the library ID field' do
      let(:user) { build(:library_id_user) }
      let(:page) { build(:page, user: user) }
      let(:mediated_page) { build(:mediated_page, user: user) }
      let(:scan) { build(:scan, user: user) }
      it { is_expected.to be_able_to(:create, page) }
      it { is_expected.to be_able_to(:create, mediated_page) }
      it { is_expected.to be_able_to(:create, mediated_page) }

      describe 'when the library is HOPKINS' do
        before { mediated_page.origin = 'HOPKINS' }
        it { is_expected.not_to be_able_to(:create, mediated_page) }
      end
    end
  end

  describe 'a webauth user' do
    let(:user) { create(:webauth_user) }

    it { is_expected.to be_able_to(:create, custom) }
    it { is_expected.to be_able_to(:create, hold_recall) }
    it { is_expected.to be_able_to(:create, mediated_page) }
    it { is_expected.to be_able_to(:create, page) }
    it { is_expected.not_to be_able_to(:create, scan) }

    describe 'who created the request' do
      before do
        request_objects.each do |object|
          allow(object).to receive_messages(user_id: user.id)
        end
      end

      # Can see the success page for their request
      it { is_expected.to be_able_to(:success, custom) }
      it { is_expected.to be_able_to(:success, hold_recall) }
      it { is_expected.to be_able_to(:success, mediated_page) }
      it { is_expected.to be_able_to(:success, page) }
      it { is_expected.to be_able_to(:success, scan) }

      # Can see the status page for their request
      it { is_expected.to be_able_to(:status, custom) }
      it { is_expected.to be_able_to(:status, hold_recall) }
      it { is_expected.to be_able_to(:status, mediated_page) }
      it { is_expected.to be_able_to(:status, page) }
      it { is_expected.to be_able_to(:status, scan) }
    end

    describe 'who did not create the requst' do
      before do
        request_objects.each do |object|
          allow(object).to receive_messages(user_id: User.create(webauth: 'some-other-user').id)
        end
      end

      # Can't see the success page for other user's requests
      it { is_expected.not_to be_able_to(:success, custom) }
      it { is_expected.not_to be_able_to(:success, hold_recall) }
      it { is_expected.not_to be_able_to(:success, mediated_page) }
      it { is_expected.not_to be_able_to(:success, page) }
      it { is_expected.not_to be_able_to(:success, scan) }

      # Can't see the status page for other user's requests
      it { is_expected.not_to be_able_to(:status, custom) }
      it { is_expected.not_to be_able_to(:status, hold_recall) }
      it { is_expected.not_to be_able_to(:status, mediated_page) }
      it { is_expected.not_to be_able_to(:status, page) }
      it { is_expected.not_to be_able_to(:status, scan) }
    end

    describe 'who is in the scan and deliver pilot group' do
      let(:user) { create(:scan_eligible_user) }

      it { is_expected.to be_able_to(:create, scan) }
    end

    describe 'who is a graduate student' do
      before do
        user.affiliation = 'stanford:student'
        user.student_type = 'Graduate'
      end

      it { is_expected.to be_able_to(:create, scan) }
    end

    describe 'who is an undergraduate' do
      before do
        user.affiliation = 'stanford:student'
        user.student_type = 'Undergraduate'
      end

      it { is_expected.not_to be_able_to(:create, scan) }
    end
  end

  describe 'a super admin' do
    let(:user) { create(:superadmin_user) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
  end

  describe 'a site admin' do
    let(:user) { create(:site_admin_user) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }

    it { is_expected.to be_able_to(:new, message) }
    it { is_expected.to be_able_to(:create, message) }
    it { is_expected.to be_able_to(:read, message) }
    it { is_expected.to be_able_to(:update, message) }
    it { is_expected.to be_able_to(:delete, message) }
  end

  describe 'an origin admin' do
    let(:user) { create(:webauth_user) }

    before do
      allow(user).to receive_messages(ldap_groups: ['FAKE-ORIGIN-LIBRARY-TEST-LDAP-GROUP'])
      request.origin = 'FAKE-ORIGIN-LIBRARY'
      custom.origin = 'FAKE-ORIGIN-LIBRARY'
      hold_recall.origin = 'FAKE-ORIGIN-LIBRARY'
      mediated_page.origin = 'FAKE-ORIGIN-LIBRARY'
      page.origin = 'FAKE-ORIGIN-LIBRARY'
      scan.origin = 'FAKE-ORIGIN-LIBRARY'
    end

    # can manage locations that they are an admin of
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }

    it { is_expected.not_to be_able_to(:new, message) }
    it { is_expected.not_to be_able_to(:create, message) }
    it { is_expected.not_to be_able_to(:read, message) }
    it { is_expected.not_to be_able_to(:update, message) }
    it { is_expected.not_to be_able_to(:delete, message) }
  end
end
