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
    @date = Date.iso8601(params[:date])
    daily_log = current_user.daily_logs.find_by(date: @date)

    return render json: { error: 'ログが見つかりません' }, status: :not_found unless daily_log

    text = daily_log.learning_items.pluck(:body_markdown).compact.join("\n")
    return render json: { results: [] } if text.blank?

    embedding = EmbeddingService.generate(text)

    embedding_record = daily_log.daily_log_embedding || daily_log.build_daily_log_embedding

    embedding_record.update!(
      embedding: embedding,
      embedding_model: EmbeddingService::MODEL
    )

    results = DailyLogEmbedding
      .joins(:daily_log)
      .where(daily_logs: { user_id: current_user.id })
      .where.not(daily_log_id: daily_log.id)
      .nearest_neighbors(:embedding, embedding, distance: "cosine")
      .limit(5)
      .map do |e|
        {
          date: e.daily_log.date,
          items: e.daily_log.learning_items.map { |i| { body: i.body_markdown, category: i.category&.name } }
        }
      end

    render json: { results: results }
  rescue ArgumentError
    render plain: 'Invalid date', status: :bad_request
  end
end
