class AddUniqueIndexToLearningItemsClientUuid < ActiveRecord::Migration[7.2]
  def change
    add_index :learning_items, :client_uuid, unique: true
  end
end
