# frozen_string_literal: true

class BalanceEnoughCheckService
  DEFAULT_TRANSFER_CAPACITY_AMOUNT =  5_000_000 * 10 ** 8

  def call
    sync_transfer_tx_status

    total_send_capacity = ClaimEvent.pending.sum(:capacity)
    official_account_balance = Account.official_account.balance
    if InnerTransfer.pending.exists? || total_send_capacity > official_account_balance
      less_amount = total_send_capacity - official_account_balance  
      inner_account = CKB::Wallet.from_hex(api, ENV["INNER_WALLET_PRIVATE_KEY"], indexer_api: indexer_api)
      offical_account = CKB::Wallet.from_hex(api,  ENV["OFFICIAL_WALLET_PRIVATE_KEY"], indexer_api: indexer_api)
      transfer_amount = less_amount + DEFAULT_TRANSFER_CAPACITY_AMOUNT
      tx_hash = inner_account.send_capacity(offical_account.address, transfer_amount, fee: 1000)
      InnerTransfer.create!(tx_hash:, amount: transfer_amount)
      false
    else
      true
    end
  end

  private
  def sync_transfer_tx_status
    InnerTransfer.pending.each do |transfer|
      tx = api.get_transaction(transfer.tx_hash)
      if tx.tx_status.status == "committed"
        ApplicationRecord.transaction do
          Account.offical_account.increment!(:balance, transfer.amount)
          transfer.update!(tx_status: tx.tx_status.status)
        end
      elsif tx.tx_status.status == "rejected"
        transfer.update!(tx_status: tx.tx_status.status)
      end
    end
  end

  def api
    @api ||= SdkApi.instance.api
  end

  def indexer_api
    @indexer_api || SdkApi.instance.indexer_api
  end
end
