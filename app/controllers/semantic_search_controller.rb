class SemanticSearchController < ApplicationController
  before_action :authenticate_user!

  def search
    query = params[:query].to_s.strip
    if query.length < 2
      render json: { error: '検索キーワードを2文字以上入力してください' }, status: :unprocessable_content
      return
    end

    render json: { results: search_results(query) }
  rescue StandardError => e
    Rails.logger.error("SemanticSearch error: #{e.message}")
    render json: { error: 'エラーが発生しました' }, status: :internal_server_error
  end

  private

  def search_results(query)
    EmbeddingService.generate(query, input_type: 'search_query')
    find_nearest_logs(vector).map { |log| format_log(log) }
  end

  def find_nearest_logs(vector)
    DailyLogEmbedding
      .joins(:daily_log)
      .where(daily_logs: { user_id: current_user.id })
      .nearest_neighbors(:embedding, vector, distance: 'cosine')
      .limit(10)
      .map(&:daily_log)
  end

  def format_log(log)
    {
      date: log.date,
      insights: log.insights&.truncate(100),
      items: log.learning_items.includes(:category).map do |item|
        { body: item.summary, category: item.category&.name }
      end
    }
  end
end
