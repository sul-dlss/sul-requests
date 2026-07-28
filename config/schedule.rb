every 1.day, roles: :production_cron  do
  rake 'data_removal:remove_old_requests'
end
every 1.day, at: '7:00am', roles: :production_cron  do
  rake 'aeon:check_for_upcoming_requests_for_the_same_item'
end
