# frozen_string_literal: true

class SendCapacityService
  def call
    ClaimEvent.transaction do
      pending_events = ClaimEvent.order(id: :desc).pending.limit(100).group_by(&:tx_hash)
      return if pending_events.blank?
      puts pending_events.count
      pending_events.each do |tx_hash, events|
        if tx_hash.present?
          tx = api.get_transaction(tx_hash)

          if tx.present?
            handle_state_change(events, tx)
          else
            # next if pending_events.keys.compact.size > 1
            handle_send_capacity(events)
          end
        else
          # puts pending_events.keys.compact
          # next if pending_events.keys.compact.size > 1
          # puts 'bbbb'
          handle_send_capacity(events)
        end
      end
    end
  end

  private
    def ckb_wallet
      @ckb_wallet ||= CKB::Wallets::NewWallet.new(api: api, indexer_api: indexer_api, from_addresses: Account.first.address_hash)
    end

    def api
      @api ||= SdkApi.instance.api
    end

    def indexer_api
      @indexer_api || SdkApi.instance.indexer_api
    end

    def handle_state_change(pending_events, tx)
      puts tx.inspect
      return if tx.tx_status.status == "pending"
      last_tx_hash = Rails.cache.read("last_transaction_hash")
      if tx.tx_status.status == "committed"
        if last_tx_hash == tx.transaction.hash
          Rails.cache.delete("last_transaction_hash")
          Rails.cache.delete("last_transaction_time")
        end
        pending_events.map { |pending_event| pending_event.processed! }
        pending_events.map { |pending_event| pending_event.update!(tx_status: tx.tx_status.status) }
        Account.official_account.decrement!(:balance, pending_events.inject(0) { |sum, event| sum + event.capacity })
      else
        pending_events.map { |pending_event| pending_event.rejected! } if ["rejected", "unknown"].include?(tx.tx_status.status)
        pending_events.map { |pending_event| pending_event.update!(tx_status: tx.tx_status.status) }
      end
    end

    def handle_send_capacity(pending_events)
      last_tx_time = Rails.cache.read("last_transaction_time")
      return if last_tx_time && Time.now.to_i - last_tx_time.to_i < 200
      to_infos = pending_events.inject({}) do |memo, event|
        if memo[event.address_hash].present?
          memo[event.address_hash] = { capacity: event.capacity + memo[event.address_hash][:capacity] }
        else
          memo[event.address_hash] = { capacity: event.capacity }
        end
        memo
      end
      puts to_infos
      tx_generator = ckb_wallet.advance_generate(to_infos: to_infos)
      tx = ckb_wallet.sign(tx_generator, ENV["OFFICIAL_WALLET_PRIVATE_KEY"])
      puts tx&.to_h.inspect
      tx_hash = api.send_transaction(tx, "passthrough")
      Rails.cache.write("last_transaction_hash", tx_hash, expires_in: 3.minutes)
      Rails.cache.write("last_transaction_time", Time.now.to_i, expires_in: 3.minutes)
      pending_events.map { |pending_event| pending_event.update!(tx_hash: tx_hash, tx_status: "pending", fee: tx_fee(tx)) }
      # rescue CKB::RPCError => e
      #   puts e


      #   puts e.backtrace.join("\n")
      #   binding.pry
    end

    def tx_fee(tx)
      input_capacities = tx.inputs.map { |input| api.get_transaction(input.previous_output.tx_hash).transaction.outputs[input.previous_output.index].capacity }.sum
      output_capacities = tx.outputs.map(&:capacity).sum

      input_capacities - output_capacities
    end
end
