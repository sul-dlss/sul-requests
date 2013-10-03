#sepc/factories/fields.rb

FactoryGirl.define do
  factory :field do |f|
    f.id 1
    f.field_name "ckey"
    f.field_label "Catalog Record Key"
  end
end