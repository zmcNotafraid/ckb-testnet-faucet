class CreateInnerTransfers < ActiveRecord::Migration[6.0]
  def change
    create_table :inner_transfers do |t|
      t.binary :tx_hash
      t.bigint :amount
      t.integer :tx_status, default: 0

      t.timestamps
    end
  end
end
