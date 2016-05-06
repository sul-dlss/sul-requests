FactoryGirl.define do
  factory :superadmin_user, class: User do
    webauth 'super-admin'

    after(:build) do |user|
      class << user
        def super_admin?
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

  factory :sal3_origin_admin_user, class: User do
    webauth 'sal3-admin'

    after(:build) do |user|
      class << user
        def admin_for_origin?(location)
          location == 'SAL3'
        end
      end
    end
  end

  factory :page_mp_origin_admin_user, class: User do
    webauth 'page-mp-admin'

    after(:build) do |user|
      class << user
        def admin_for_origin?(location)
          location == 'PAGE-MP'
        end
      end
    end
  end

  factory :webauth_user, class: User do
    webauth 'some-webauth-user'
  end

  factory :scan_eligible_user, class: User do
    webauth 'some-eligible-user'

    after(:build) do |user|
      user.affiliation = Settings.scan_pilot_groups.first
    end
  end

  factory :non_webauth_user, class: User do
    name 'Jane Stanford'
    email 'jstanford@stanford.edu'
  end

  factory :library_id_user, class: User do
    library_id '12345678'
  end

  factory :anon_user, class: User do
  end
end
