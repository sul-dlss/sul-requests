# frozen_string_literal: true

FactoryBot.define do
  factory :superadmin_user, class: 'User' do
    sunetid { 'super-admin' }
    email { 'super-admin@stanford.edu' }
    after(:build) do |user|
      user.ldap_group_string = 'sul:requests-super-admin'
    end
  end

  factory :site_admin_user, class: 'User' do
    sunetid { 'site-admin' }
    after(:build) do |user|
      user.ldap_group_string = 'sul:requests-site-admin'
    end
  end

  factory :art_origin_admin_user, class: 'User' do
    sunetid { 'art-admin' }
    after(:build) do |user|
      user.ldap_group_string = 'sul:requests-art'
    end
  end

  factory :page_mp_origin_admin_user, class: 'User' do
    sunetid { 'page-mp-admin' }
    after(:build) do |user|
      user.ldap_group_string = 'sul:requests-branner'
    end
  end

  factory :sso_user, class: 'User' do
    sunetid { 'some-sso-user' }
    email { 'some-sso-user@stanford.edu' }
    name { 'Some SSO User' }
    patron_key { 'some-uuid' }

    after(:build) do |user|
      class << user
        def sponsor?
          false
        end

        def proxy?
          false
        end
      end
    end
  end

  factory :sequence_sso_user, class: 'User' do
    sequence(:sunetid) { |n| "some-sso-user-#{n}" }
    sequence(:email) { |n| "some-sso-user-#{n}@stanford.edu" }
  end

  factory :scan_eligible_user, class: 'User' do
    sunetid { 'some-eligible-user' }
    email { 'some-eligible-user@stanford.edu' }
    patron_key { 'some-uuid' }
  end

  factory :non_sso_user, class: 'User' do
    name { 'Jane Stanford' }
    email { 'jstanford@stanford.edu' }
  end

  factory :library_id_user, class: 'User' do
    library_id { '12345678' }
  end

  factory :anon_user, class: 'User'
end
