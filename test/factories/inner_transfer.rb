# frozen_string_literal: true

FactoryBot.define do
  factory :inner_transfer do
    tx_hash { "0x#{SecureRandom.hex(32)}" }
    amount { 10_000_000 * 10**8 }
    tx_status { "committed" }
  end
end
