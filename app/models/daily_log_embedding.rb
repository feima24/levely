class DailyLogEmbedding < ApplicationRecord
  belongs_to :daily_log
  has_neighbors :embedding
end
