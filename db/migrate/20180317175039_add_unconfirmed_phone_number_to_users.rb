class AddUnconfirmedPhoneNumberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :unconfirmed_phone_number, :string
  end
end
