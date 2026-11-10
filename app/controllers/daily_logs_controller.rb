class DailyLogsController < ApplicationController
  before_action :authenticate_user!

  def show
    load_daily_log
    respond_to do |format|
      format.html { redirect_to monthly_path(@date.strftime('%Y-%m')) }
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

  def generate_embedding
    @date = Date.iso8601(params[:date])
    daily_log = current_user.daily_logs.find_by(date: @date)

    return skip_embedding(daily_log) if skip_embedding?(daily_log)

    upsert_embedding(daily_log)

    render json: { success: true }
  end

  private

  def upsert_embedding(daily_log)
    vector = EmbeddingService.generate(daily_log_text(daily_log), input_type: 'search_query')
    embedding = daily_log.daily_log_embedding || daily_log.build_daily_log_embedding
    embedding.update!(embedding: vector, embedding_model: EmbeddingService::MODEL)
  end

  def embedding_for(daily_log)
    upsert_embedding(daily_log) unless daily_log.daily_log_embedding
    daily_log.daily_log_embedding.embedding
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

  def daily_log_text(daily_log)
    [*daily_log.learning_items.pluck(:summary), daily_log.insights].compact_blank.join("\n")
  end

  def skip_embedding?(daily_log)
    daily_log.nil? || daily_log_text(daily_log).blank?
  end

  def skip_embedding(daily_log)
    daily_log&.daily_log_embedding&.destroy
    render json: { success: true, skipped: true }
  end
end
