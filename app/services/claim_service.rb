# frozen_string_literal: true

class ClaimService
  attr_reader :address_hash, :amount, :remote_ip

  def initialize(address_hash:, amount:, remote_ip:)
    @address_hash = address_hash
    @amount = amount
    @remote_ip = remote_ip
  end

  def call
    ApplicationRecord.transaction do
      init_account!

      account = Account.lock.find_by(address_hash: address_hash)

      raise Errors::Invalid.new(errors: { amount: "The amount you claimed are greater than your remaining." }) if account.balance + amount > Account::MAX_CAPACITY_PER_MONTH

      account.balance += amount
      account.save!

      claim_event = ClaimEvent.new(address_hash: address_hash, created_at_unixtimestamp: Time.current.to_i,
        capacity: amount, ip_addr: remote_ip)
      claim_event.save!

      Rails.cache.write("LIMIT_#{address_hash}", Date.today) if account.balance == Account::MAX_CAPACITY_PER_MONTH

      claim_event
    rescue ActiveRecord::RecordInvalid
      raise Errors::Invalid.new(errors: claim_event.errors.to_h)
    end
  end

  private

  def init_account!
    account = Account.create_or_find_by!(address_hash: address_hash)
    value = Rails.cache.read("LIMIT_#{address_hash}")
    if value && value.month != Date.today.month
      account.update!(balance: 0)
      Rails.cache.delete("LIMIT#{address_hash}")
    end
  end
end
