class InnerTransfer < ApplicationRecord
  enum tx_status: { pending: 0, proposed: 1, committed: 2, rejected: 3, unknown: 4 }, _prefix: "tx"
end

# == Schema Information
#
# Table name: inner_transfers
#
#  id         :bigint           not null, primary key
#  amount     :bigint
#  tx_hash    :binary
#  tx_status  :integer          default("pending")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
