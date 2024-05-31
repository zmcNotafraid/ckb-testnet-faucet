# frozen_string_literal: true

class ClaimEventsController < ApplicationController
  before_action :check_claim_limit, only: :create
  before_action :set_amount, only: :create
  before_action :valid_claim_amount, only: :create
  before_action :valid_claim_address_hash, only: :create

  def index
    account = Account.official_account
    claim_events = ClaimEvent.recent.limit(ClaimEvent::DEFAULT_CLAIM_EVENT_SIZE)
    remaining =
      if params[:address_hash].present?
        user = Account.find_by(address_hash: params[:address_hash])
        (Account::MAX_CAPACITY_PER_MONTH - (user&.balance || 0))/(10 **8)
      end

    render json: { claimEvents: ClaimEventSerializer.new(claim_events).serializable_hash, officialAccount: { addressHash: account.address_hash, balance: account.ckb_balance }, userAccount: { address_hash: params[:address_hash], remaining: remaining} }
  end

  def show
    claim_events = ClaimEvent.where(address_hash: params[:id]).recent.limit(15)
    render json: ClaimEventSerializer.new(claim_events)
  end

  def create
    Rails.logger.info("=======================Request ENV: #{request.env.inspect}")
    claim_event = ClaimService.new(address_hash: claim_events_params[:address_hash], amount: @amount, remote_ip: request.remote_ip).call()

    render json: ClaimEventSerializer.new(claim_event)
  end

  private
    def claim_events_params
      params.require(:claim_event).permit(:address_hash, :amount)
    end

    def set_amount
      @amount = claim_events_params[:amount].to_i * 10 ** 8
    end

    def check_claim_limit
      value = Rails.cache.read("LIMIT_#{claim_events_params[:address_hash]}")

      raise Errors::Invalid.new(errors: { amount: "Amount is already reached maximum limit." }) if value && value.month == Date.today.month
    end

    def valid_claim_amount
      raise Errors::Invalid.new(errors: { amount: "Params amount is not valid." }) if ["10000", "100000", "300000"].exclude?(claim_events_params[:amount])
    end

    def valid_claim_address_hash
      claim_event = ClaimEvent.new(address_hash: claim_events_params[:address_hash], created_at_unixtimestamp: Time.current.to_i,
      capacity: @amount, ip_addr: request.remote_ip)

      claim_event.validate!
    rescue ActiveRecord::RecordInvalid
      raise Errors::Invalid.new(errors: claim_event.errors.to_h)
    end
end
