class DailyLogsController < ApplicationController
  before_action :authenticate_user!

  # 日別ログの表示
  def show
    @date = Date.iso8601(params[:date])
    @daily_log = current_user.daily_logs.find_by(date: @date)
    @learning_items = @daily_log&.learning_items&.includes(:category) || []
    @categories = current_user.categories.order(:name)
  rescue ArgumentError
    render plain: 'Invalid date', status: :bad_request
  end

  # 関連する日別ログの検索
  def find_related
    daily_log = current_user.daily_logs.find_by!(date: params[:date])
    related_logs = related_logs_for(daily_log)

    render json: { results: related_logs_json(related_logs) }
  end

  private

  def related_logs_for(daily_log)
    embedding = embedding_for(daily_log)

    DailyLogEmbedding
      .joins(:daily_log)
      .where(daily_logs: { user_id: current_user.id })
      .where.not(daily_log_id: daily_log.id)
      .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      .limit(5)
      .map(&:daily_log)
  end

  def related_logs_json(related_logs)
    related_logs.map do |log|
      {
        date: log.date,
        items: log.learning_items.map { |item| learning_item_json(item) }
      }
    end
  end

  def learning_item_json(item)
    {
      body: item.body_markdown,
      category: item.category&.name
    }
  end

  def embedding_for(daily_log)
    DailyLogEmbedding.find_or_create_by!(daily_log: daily_log) do |record|
      record.embedding = EmbeddingService.generate(daily_log_text(daily_log))
    end.embedding
  end

  def daily_log_text(daily_log)
    daily_log.learning_items.pluck(:content).join("\n")
  end
end
