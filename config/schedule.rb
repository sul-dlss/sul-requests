every 1.day, roles: :production_cron  do
  rake 'data_removal:remove_old_requests'
end

every 4.hours, roles: :production_cron do
  runner 'WarmupAeonActivitiesJob.perform_later'
end
