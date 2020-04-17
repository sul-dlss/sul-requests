every '30 11 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '30 15 * * 1-5', roles: :production_cron do
  runner 'PicklistMailer.deliver_picklist "SPEC-COLL"'
end

every '* * * * *' do
  runner 'ExpireCdlCheckoutsJob.perform_later'
end

every 1.day, roles: :production_cron  do
  rake 'data_removal:remove_old_requests'
end
