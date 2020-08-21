every '30 11 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '30 15 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end
