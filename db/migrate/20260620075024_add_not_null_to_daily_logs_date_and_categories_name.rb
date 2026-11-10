class AddNotNullToDailyLogsDateAndCategoriesName < ActiveRecord::Migration[7.2]
  def up
    change_column_null :daily_logs, :date, false
    change_table :categories, bulk: true do |t|
      t.change :name, :string, null: false
      t.change :normalized_name, :string, null: false
    end
  end

  def down
    change_column_null :daily_logs, :date, true
    change_table :categories, bulk: true do |t|
      t.change :name, :string, null: true
      t.change :normalized_name, :string, null: true
    end
  end
end
