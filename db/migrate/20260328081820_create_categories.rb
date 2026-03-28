class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :normalized_name

      t.timestamps
    end

    add_index :categories, [:user_id, :normalized_name], unique: true
  end
end
