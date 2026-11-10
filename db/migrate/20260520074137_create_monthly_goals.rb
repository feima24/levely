class CreateMonthlyGoals < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :monthly_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false

      t.string :goal1, null: false
      t.string :goal2, null: false
      t.string :goal3, null: false

      t.boolean :completed1, null: false, default: false
      t.boolean :completed2, null: false, default: false
      t.boolean :completed3, null: false, default: false

      t.timestamps
    end

    add_index :monthly_goals, %i[user_id month], unique: true
  end
end
