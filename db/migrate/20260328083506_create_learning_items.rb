class CreateLearningItems < ActiveRecord::Migration[7.2]
  def change
    create_table :learning_items do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.text :body_markdown
      t.integer :duration_minutes
      t.integer :lock_version, null: false, default: 0
      t.string :client_uuid

      t.timestamps
    end
  end
end
