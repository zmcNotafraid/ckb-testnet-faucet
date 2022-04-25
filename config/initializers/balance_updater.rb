

BalanceUpdater = Concurrent::TimerTask.new(execution_interval: rand(2.hours..4.hours)) do
  puts 'Update balance'
  ActiveRecord::Base.connection_pool.with_connection do
    UpdateOfficialAccountBalanceService.call
  end
end
BalanceUpdater.execute

Sender =  Concurrent::TimerTask.new(execution_interval: 10) do
  puts 'Sending capacity'
  ActiveRecord::Base.connection_pool.with_connection do
    SendCapacityService.new.call
  end
end
Sender.execute
