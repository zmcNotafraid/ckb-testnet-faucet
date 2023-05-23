class AddAddressHashUniqueIndexToAccount < ActiveRecord::Migration[6.0]
  def change
    add_index :accounts, :address_hash, unique: true
  end
end
