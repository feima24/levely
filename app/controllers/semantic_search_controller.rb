class SemanticSearchController < ApplicationController
  before_action :authenticate_user!

  def search
    query = params[:query].to_s.strip
    if query.length < 2
      render json: { error: '検索キーワードを2文字以上入力してください' }, status: :unprocessable_entity
      return
    end

    vector = EmbeddingService.generate(query)
    results = DailyLogEmbedding
      .joins(:daily_log)
      .where(daily_logs: { user_id: current_user.id })
      .nearest_neighbors(:embedding, vector, distance: 'cosine')
      .limit(10)
      .map(&:daily_log)

    render json: { results: format_results(results) }
  rescue StandardError => e
    Rails.logger.error("SemanticSearch error: #{e.message}")
    render json: { error: 'エラーが発生しました' }, status: :internal_server_error
  end

  private

  def format_results(logs)
    logs.map do |log|
      {
        date: log.date,
        insights: log.insights&.truncate(100),
        items: log.learning_items.includes(:category).map { |item|
          { body: item.summary, category: item.category&.name }
        }
      }
    end
  end
end
