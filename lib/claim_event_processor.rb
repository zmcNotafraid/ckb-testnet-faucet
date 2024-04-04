# frozen_string_literal: true

require_relative "../config/environment"

BalanceUpdater = Concurrent::TimerTask.new(execution_interval: 3.minute) do
  puts 'Update balance'
  ActiveRecord::Base.connection_pool.with_connection do
    UpdateOfficialAccountBalanceService.call
  end
end
BalanceUpdater.execute

loop do
  puts 'Sending capacity'
  SendCapacityService.new.call
  sleep(10)
end
