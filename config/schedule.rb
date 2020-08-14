every '30 11 * * 1-5' do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '30 15 * * 1-5' do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end
