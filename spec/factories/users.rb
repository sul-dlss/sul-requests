FactoryGirl.define do
  factory :superadmin_user, class: User do
    webauth 'super-admin'

    after(:build) do |user|
      class << user
        def superadmin?
          true
        end
      end
    end
  end

  factory :site_admin_user, class: User do
    webauth 'site-admin'

    after(:build) do |user|
      class << user
        def site_admin?
          true
        end
      end
    end
  end

  factory :webauth_user, class: User do
    webauth 'some-webauth-user'
  end

  factory :non_webauth_user, class: User do
    name 'Jane Stanford'
    email 'jstanford@stanford.edu'
  end

  factory :anon_user, class: User do
  end
end
