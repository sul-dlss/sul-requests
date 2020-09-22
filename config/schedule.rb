every '30 11 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '30 15 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '* * * * *'do
  runner 'ExpireCdlCheckoutsJob.perform_later'
end

every '0 * * * *' do
  runner 'PollForCdlHoldsJob.perform_later'
end
