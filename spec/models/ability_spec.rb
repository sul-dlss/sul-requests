require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:request) { Request.new }
  let(:custom) { Custom.new }
  let(:hold_recall) { HoldRecall.new }
  let(:mediated_page) { MediatedPage.new }
  let(:page) { Page.new }
  let(:scan) { Scan.new }
  subject { Ability.new(user) }
  describe 'an anonymous user' do
    let(:user) { nil }

    it { is_expected.to be_able_to(:new, custom) }
    it { is_expected.not_to be_able_to(:create, custom) }
    it { is_expected.not_to be_able_to(:read, custom) }
    it { is_expected.not_to be_able_to(:update, custom) }
    it { is_expected.not_to be_able_to(:delete, custom) }

    it { is_expected.to be_able_to(:new, hold_recall) }
    it { is_expected.not_to be_able_to(:create, hold_recall) }
    it { is_expected.not_to be_able_to(:read, hold_recall) }
    it { is_expected.not_to be_able_to(:update, hold_recall) }
    it { is_expected.not_to be_able_to(:delete, hold_recall) }

    it { is_expected.to be_able_to(:new, mediated_page) }
    it { is_expected.not_to be_able_to(:create, mediated_page) }
    it { is_expected.not_to be_able_to(:read, mediated_page) }
    it { is_expected.not_to be_able_to(:update, mediated_page) }
    it { is_expected.not_to be_able_to(:delete, mediated_page) }

    it { is_expected.to be_able_to(:new, page) }
    it { is_expected.not_to be_able_to(:create, page) }
    it { is_expected.not_to be_able_to(:read, page) }
    it { is_expected.not_to be_able_to(:update, page) }
    it { is_expected.not_to be_able_to(:delete, page) }

    it { is_expected.to be_able_to(:new, scan) }
    it { is_expected.not_to be_able_to(:create, scan) }
    it { is_expected.not_to be_able_to(:read, scan) }
    it { is_expected.not_to be_able_to(:update, scan) }
    it { is_expected.not_to be_able_to(:delete, scan) }
  end

  describe 'a webauth user' do
    let(:user) { User.new }
    before { allow(user).to receive_messages(webauth_user?: true) }

    it { is_expected.to be_able_to(:create, custom) }
    it { is_expected.to be_able_to(:create, hold_recall) }
    it { is_expected.to be_able_to(:create, mediated_page) }
    it { is_expected.to be_able_to(:create, page) }
    it { is_expected.to be_able_to(:create, scan) }
  end

  pending 'a user with an email and name' do
    let(:user) { User.new(email: 'email@example.com', name: 'Jane Stanford') }

    it { is_expected.to be_able_to(:create, custom) }
    it { is_expected.to be_able_to(:create, hold_recall) }
    it { is_expected.to be_able_to(:create, mediated_page) }
    it { is_expected.to be_able_to(:create, page) }
    it { is_expected.not_to be_able_to(:create, scan) }
  end

  describe 'a super admin' do
    let(:user) { User.new }
    before { allow(user).to receive_messages(superadmin?: true) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
  end

  describe 'a site admin' do
    let(:user) { User.new }
    before { allow(user).to receive_messages(site_admin?: true) }

    # can manage anything
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
  end

  describe 'an origin admin' do
    let(:user) { User.new }

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
  end

  describe 'a destination admin' do
    let(:user) { User.new }

    before do
      allow(user).to receive_messages(ldap_groups: ['FAKE-DESTINATION-LIBRARY-TEST-LDAP-GROUP'])
      request.destination = 'FAKE-DESTINATION-LIBRARY'
      custom.destination = 'FAKE-DESTINATION-LIBRARY'
      hold_recall.destination = 'FAKE-DESTINATION-LIBRARY'
      mediated_page.destination = 'FAKE-DESTINATION-LIBRARY'
      page.destination = 'FAKE-DESTINATION-LIBRARY'
      scan.destination = 'FAKE-DESTINATION-LIBRARY'
    end

    # can manage locations that they are an admin of
    it { is_expected.to be_able_to(:manage, request) }
    it { is_expected.to be_able_to(:manage, custom) }
    it { is_expected.to be_able_to(:manage, hold_recall) }
    it { is_expected.to be_able_to(:manage, mediated_page) }
    it { is_expected.to be_able_to(:manage, page) }
    it { is_expected.to be_able_to(:manage, scan) }
  end
end
