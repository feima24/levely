class DailyLogsController < ApplicationController
  before_action :authenticate_user!

  def show
    @date = Date.iso8601(params[:date])
    @daily_log = current_user.daily_logs.find_by(date: @date)
    @learning_items = @daily_log&.learning_items&.includes(:category) || []
    @categories = current_user.categories.order(:name)
  rescue Date::Error, ArgumentError
    render plain: "Invalid date", status: :bad_request
  end
end
