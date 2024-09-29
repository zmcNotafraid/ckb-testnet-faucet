# frozen_string_literal: true

require "test_helper"

class InnerTransferTest < ActiveSupport::TestCase
  test "should create new inner transfer" do
    tx_hash= "0x50a83410d6827f5bc46498815b417a8dd309b3659b5c44cc88166d704658b439"
    transfer = create(:inner_transfer, tx_hash: tx_hash)
    assert_equal tx_hash, InnerTransfer.last.tx_hash
  end
end
