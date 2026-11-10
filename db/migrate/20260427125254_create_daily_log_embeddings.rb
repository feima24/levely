class CreateDailyLogEmbeddings < ActiveRecord::Migration[7.2]
  def change
    create_table :daily_log_embeddings do |t|
      t.references :daily_log, null: false, foreign_key: true
      t.vector :embedding, limit: 1024
      t.string :embedding_model, null: false # 将来モデルを変えたとき区別用
      t.timestamps
    end
  end
end
