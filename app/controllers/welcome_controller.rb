# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    account = Account.official_account
    claim_events = ClaimEvent.recent.limit(ClaimEvent::DEFAULT_CLAIM_EVENT_SIZE)
    remaining = 
    if params[:address_hash].present?
      user = Account.find_by(address_hash: params[:address_hash])
      (Account::MAX_CAPACITY_PER_MONTH - (user&.balance || 0))/(10 **8)
    end

    render component: "Welcome", props: { 
      claim_events: ClaimEventSerializer.new(claim_events).serializable_hash, 
      official_account: { 
        address_hash: account.address_hash, 
        balance: account.ckb_balance 
      }, 
      userAccount: {
        address_hash: params[:address_hash],
        remaining: remaining
      },
      aggron_explorer_host: ENV['TESTNET_EXPLORER_HOST'] 
    }
  end
end
