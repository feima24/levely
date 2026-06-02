class AddConfirmableToUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
    end
    add_index :users, :confirmation_token, unique: true

    User.update_all confirmed_at: Time.current # rubocop:disable Rails/SkipsModelValidations
  end
end
