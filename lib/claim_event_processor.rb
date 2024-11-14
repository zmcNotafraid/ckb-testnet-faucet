# frozen_string_literal: true

require_relative "../config/environment"

# BalanceUpdater = Concurrent::TimerTask.new(execution_interval: 3.hour) do
#   puts 'Sync Offical Account Balance'
#   ActiveRecord::Base.connection_pool.with_connection do
#     UpdateOfficialAccountBalanceService.call
#   end
# end
# BalanceUpdater.execute

loop do
  Rails.logger.info "Check Offical Account Balance Enough"
  enough = BalanceEnoughCheckService.new.call
  if enough
    Rails.logger.info 'Sending capacity'
    SendCapacityService.new.call
  end
  sleep(10)
end
