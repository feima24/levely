class DailyLogsController < ApplicationController
  before_action :authenticate_user!

  def show
    load_daily_log
    respond_to do |format|
      format.html
      format.json { render json: daily_log_json }
    end
  rescue ArgumentError
    render plain: 'Invalid date', status: :bad_request
  end

  def update
    @date = Date.iso8601(params[:date])
    @daily_log = current_user.daily_logs.find_or_initialize_by(date: @date)
    @daily_log.insights = params[:insights]

    if @daily_log.save
      render json: { success: true }
    else
      render json: { errors: @daily_log.errors.full_messages }, status: :unprocessable_content
    end
  end

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
      body: item.summary,
      category: item.category&.name
    }
  end

  def load_daily_log
    @date = Date.iso8601(params[:date])
    @daily_log = current_user.daily_logs.find_by(date: @date)
    @learning_items = @daily_log&.learning_items&.includes(:category) || []
    @categories = current_user.categories.order(:name)
  end

  def daily_log_json
    {
      date: @date,
      has_record: @daily_log.present?,
      insights: @daily_log&.insights,
      learning_items: @learning_items.map { |item| learning_item_detail(item) }
    }
  end

  def learning_item_detail(item)
    {
      id: item.id,
      category_name: item.category&.name,
      summary: item.summary,
      duration_minutes: item.duration_minutes,
      lock_version: item.lock_version
    }
  end

  def embedding_for(daily_log)
    DailyLogEmbedding.find_or_create_by!(daily_log: daily_log) do |record|
      record.embedding = EmbeddingService.generate(daily_log_text(daily_log))
    end.embedding
  end

  def daily_log_text(daily_log)
    daily_log.learning_items.pluck(:summary).join("\n")
  end
end
