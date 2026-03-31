# app/controllers/learning_items_controller.rb
class LearningItemsController < ApplicationController
  before_action :authenticate_user!

  def create
    date = Date.iso8601(params[:date])
    @item = build_learning_item(date)

    if @item.save
      redirect_to daily_log_path(date)
    else
      render plain: @item.errors.full_messages.join(", "), status: :unprocessable_content
    end
  rescue ArgumentError
    render plain: "Invalid date", status: :bad_request
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
    # current_userのスコープで引く（他人のアイテムを触らせない）
    current_user.daily_logs
                .joins(:learning_items)
                .merge(LearningItem.where(id: params[:id]))
                .first!
                .learning_items
                .find(params[:id])
  end

  def learning_item_params
    params.require(:learning_item).permit(
      :category_id, :body_markdown, :duration_minutes,
      :lock_version, :client_uuid
    )
  end

  def build_learning_item(date)
    daily_log = current_user.daily_logs.find_or_create_by!(date: date)
    daily_log.learning_items.build(learning_item_params)
  end
end
