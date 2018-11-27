# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    text { 'MyText' }
    start_at { '2000-05-19 11:02:38' }
    end_at { '2500-05-19 11:02:38' }
    library { 'SPEC-COLL' }
    request_type { 'page' }
  end
end
