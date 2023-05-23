# frozen_string_literal: true

require "test_helper"

class ClaimEventValidatorTest < ActiveSupport::TestCase
  test "should create new claim event when address hash is valid and passed all validations" do
    assert_difference -> { ClaimEvent.count }, 1 do
      create(:claim_event)
    end
  end

  test "should reject claim when address hash is invalid" do
    address_hash = "123"
    claim_event = build(:claim_event, address_hash: address_hash)

    assert_not claim_event.save
    assert_equal "Address is invalid.", claim_event.errors[:address_hash].first
  end

  test "should reject claim when address is not short payload format" do
    address_hash = "ckt1qyqlqn8vsj7r0a5rvya76tey9jd2rdnca8lqh4kcuq"
    claim_event = build(:claim_event, address_hash: address_hash)

    assert_not claim_event.save
    assert_equal "Address cannot be multisig short payload format.", claim_event.errors[:address_hash].first
  end

  test "should reject claim when address is not testnet address" do
    address_hash = "ckb1qyqq5jr0hrm0uc8hduqp6cmjmfqmayghyfvspnxmu4"
    claim_event = build(:claim_event, address_hash: address_hash)

    assert_not claim_event.save
    assert_equal "Address must be a testnet address.", claim_event.errors[:address_hash].first
  end

  test "should reject claim when target address hash is official address" do
    account = Account.first
    claim_event = build(:claim_event, address_hash: account.address_hash)

    assert_not claim_event.save
    assert_equal "Does not support transfers to official address.", claim_event.errors[:address_hash].first
  end
end
