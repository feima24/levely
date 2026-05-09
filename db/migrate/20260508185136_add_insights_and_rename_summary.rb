class AddInsightsAndRenameSummary < ActiveRecord::Migration[7.2]
  def change
    add_column :daily_logs, :insights, :text
    rename_column :learning_items, :body_markdown, :summary
  end
end
