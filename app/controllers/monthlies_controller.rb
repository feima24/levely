class MonthliesController < ApplicationController
  def show
    @month = Date.iso8601("#{params[:month]}-01")
    daily_logs = current_user.daily_logs
                   .where(date: @month.beginning_of_month..@month.end_of_month)
                   .includes(learning_items: :category)

    # カレンダー用: { date => total_minutes }
    @calendar_data = daily_logs.each_with_object({}) do |log, h|
      h[log.date] = log.learning_items.sum { |i| i.duration_minutes.to_i }
    end

    # カテゴリ別合計: { category => total_minutes }
    @category_totals = daily_logs
                         .flat_map(&:learning_items)
                         .reject { |i| i.duration_minutes.nil? }
                         .group_by(&:category)
                         .transform_values { |items| items.sum(&:duration_minutes) }
                         .sort_by { |_, v| -v }
                         .to_h
  rescue ArgumentError
    redirect_to monthly_path(month: Time.zone.today.strftime('%Y-%m'))
  end
end
