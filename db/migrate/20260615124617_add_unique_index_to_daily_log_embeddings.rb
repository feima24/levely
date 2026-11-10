class AddUniqueIndexToDailyLogEmbeddings < ActiveRecord::Migration[7.2]
  def change
    remove_index :daily_log_embeddings, :daily_log_id
    add_index :daily_log_embeddings, :daily_log_id, unique: true
  end
end
