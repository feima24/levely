# rubocop:disable Rails/BulkChangeTable
class ChangeEmbeddingDimensionTo1024 < ActiveRecord::Migration[7.2]
  def change
    remove_column :daily_log_embeddings, :embedding, :vector, limit: 1536
    add_column :daily_log_embeddings, :embedding, :vector, limit: 1024
  end
end
# rubocop:enable Rails/BulkChangeTable
