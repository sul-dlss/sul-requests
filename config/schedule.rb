every '* * * * *' do
  runner 'ExpireCdlCheckoutsJob.perform_now'
end

every 1.day, roles: :production_cron  do
  rake 'data_removal:remove_old_requests'
end
