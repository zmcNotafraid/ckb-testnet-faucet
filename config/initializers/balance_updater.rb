

BalanceUpdater = Concurrent::TimerTask.new(execution_interval: rand(2.hours..4.hours)) do
  UpdateOfficialAccountBalanceService.call
end
BalanceUpdater.execute

Sender =  Concurrent::TimerTask.new(execution_interval: 10) do
  SendCapacityService.new.call
end
Sender.execute
