# app/controllers/learning_items_controller.rb
class LearningItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    date = Date.iso8601(params[:date])
    @item = build_learning_item(date)

    if @item.save
      redirect_to daily_log_path(date)
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_content
    end
  rescue ArgumentError
    render plain: 'Invalid date', status: :bad_request
  end

  def update
    @item = find_item
    if @item.update(learning_item_params)
      render json: @item
    else
      render json: { errors: @item.errors }, status: :unprocessable_content
    end
  end

  def destroy
    @item = find_item
    daily_log = @item.daily_log
    @item.destroy!

    # 最後の行を削除したらDailyLogも消す
    daily_log.destroy! if daily_log.learning_items.empty?

    redirect_to daily_log_path(daily_log.date), status: :see_other
  end

  private

  def find_item
    LearningItem
      .joins(:daily_log)
      .where(daily_logs: { user: current_user })
      .find(params[:id])
  end

  def learning_item_params
    params.require(:learning_item).permit(
      :body_markdown, :duration_minutes,
      :lock_version, :client_uuid
    )
  end

  def build_learning_item(date)
    daily_log = current_user.daily_logs.find_by(date: date) ||
                current_user.daily_logs.build(date: date)
    category = find_or_create_category(params[:learning_item][:category_name])
    daily_log.learning_items.build(learning_item_params.merge(category: category))
  end

  def find_or_create_category(name)
    normalized = name.to_s.strip.downcase.gsub(/\s+/, ' ')
    current_user.categories.find_or_initialize_by(normalized_name: normalized).tap do |cat|
      cat.name ||= name.strip
      cat.save!
    end
  end
end
