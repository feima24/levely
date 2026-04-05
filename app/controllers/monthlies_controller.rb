class MonthliesController < ApplicationController
  def show
    @month = Date.iso8601("#{params[:month]}-01")
    daily_logs = current_user.daily_logs
                             .where(date: @month.all_month)
                             .includes(learning_items: :category)

    @calendar_data = build_calendar_data(daily_logs)
    @category_totals = build_category_totals(daily_logs)
  rescue ArgumentError
    redirect_to monthly_path(Time.zone.today.strftime('%Y-%m'))
  end

  private

  # カレンダー用: { date => total_minutes }
  def build_calendar_data(daily_logs)
    daily_logs.to_h do |log|
      [log.date, log.learning_items.sum { |i| i.duration_minutes.to_i }]
    end
  end

  # カテゴリ別合計: { category => total_minutes }
  def build_category_totals(daily_logs)
    daily_logs
      .flat_map(&:learning_items)
      .reject { |i| i.duration_minutes.nil? }
      .group_by(&:category)
      .transform_values { |items| items.sum(&:duration_minutes) }
      .sort_by { |_, v| -v }
      .to_h
  end
end
