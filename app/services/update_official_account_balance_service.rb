# frozen_string_literal: true

class UpdateOfficialAccountBalanceService
  def self.call
    api = CKB::API.new(host: ENV["CKB_NODE_URL"])
    ckb_wallet = CKB::Wallet.from_hex(api, ENV["OFFICIAL_WALLET_PRIVATE_KEY"])
    balance = api.get_cells_capacity({ script: ckb_wallet.lock.to_h, script_type: "lock" })
    Account.official_account.update(balance: balance.capacity)
  end
end
