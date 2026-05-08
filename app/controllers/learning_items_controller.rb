class LearningItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    date = Date.iso8601(params[:date])
    @item = build_learning_item(date)

    if @item.save
      render json: {
        id: @item.id,
        lock_version: @item.lock_version,
        client_uuid: @item.client_uuid,
        summary: @item.summary,
        category_name: @item.category&.name,
        duration_minutes: @item.duration_minutes
      }, status: :created
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_content
    end
  rescue ArgumentError
    render plain: 'Invalid date', status: :bad_request
  end

  def update
    @item = find_item
    apply_params_to(@item)

    if @item.save
      render json: @item.as_json(only: %i[id lock_version])
    else
      render json: { errors: @item.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::StaleObjectError
    render json: { conflict: true }, status: :conflict
  end

  def destroy
    @item = find_item
    daily_log = @item.daily_log
    @item.destroy!
    daily_log.destroy! if daily_log.learning_items.empty? && daily_log.insights.blank?
    head :no_content
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
      :summary, :duration_minutes,
      :lock_version, :client_uuid
    )
  end

  def learning_item_params_without_lock
    params.require(:learning_item).permit(
      :summary, :duration_minutes, :client_uuid
    )
  end

  def apply_params_to(item)
    if params[:force]
      item.reload
      item.assign_attributes(learning_item_params_without_lock)
    else
      item.assign_attributes(learning_item_params)
    end
  end

  def build_learning_item(date)
    daily_log = current_user.daily_logs.find_or_initialize_by(date: date)
    category = find_or_create_category(params[:learning_item][:category_name])
    daily_log.learning_items.build(learning_item_params.merge(category: category))
  end

  def find_or_create_category(name)
    return nil if name.blank?
    normalized = name.to_s.strip.downcase.gsub(/\s+/, ' ')
    current_user.categories.find_or_initialize_by(normalized_name: normalized).tap do |cat|
      cat.name ||= name.strip
      cat.save!
    end
  end
end
