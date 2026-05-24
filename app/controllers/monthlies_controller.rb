class MonthliesController < ApplicationController
  def show
    @month = Date.iso8601("#{params[:month]}-01")
    load_monthly_data
    load_stats
    load_today_data
    load_monthly_goal
  rescue ArgumentError
    redirect_to monthly_path(Time.zone.today.strftime('%Y-%m'))
  end

  private

  def load_monthly_data
    daily_logs = current_user.daily_logs
                             .where(date: @month.all_month)
                             .includes(learning_items: :category)

    @calendar_data = build_calendar_data(daily_logs)
    @category_totals = build_category_totals(daily_logs)
    @weekly_totals = build_weekly_totals(daily_logs)

    colors = %w[#ffd700 #4caf50 #ff6b6b #87ceeb #ff9800 #ab47bc #26a69a #ef5350]
    @category_color_map = @category_totals.each_with_index.to_h { |(cat, _), i| [cat&.name, colors[i % colors.length]] }
  end

  def load_stats
    @monthly_total_minutes = @category_totals.values.sum
    @weekly_minutes = calc_weekly_minutes
    @streak_count = calc_streak
  end

  def load_today_data
    @today = Time.zone.today
    @today_log = current_user.daily_logs.find_by(date: @today)
    @today_items = @today_log&.learning_items&.includes(:category) || []
    @categories = current_user.categories.order(:name)
  end

  def build_calendar_data(daily_logs)
    daily_logs
      .select(&:recorded?)
      .to_h { |log| [log.date, log.learning_items.sum { |i| i.duration_minutes.to_i }] }
  end

  def build_weekly_totals(daily_logs)
    logs_by_date = daily_logs.index_by(&:date)

    weekly_date_ranges.filter_map do |days|
      week_logs = days.filter_map { |d| logs_by_date[d] }
      category_minutes = week_logs.flat_map(&:learning_items)
                                  .reject { |i| i.duration_minutes.nil? }
                                  .group_by(&:category)
                                  .transform_values { |items| items.sum(&:duration_minutes) }
                                  .sort_by { |_, m| -m }
                                  .to_h
      total = category_minutes.values.sum
      {
        start_day: days.first.day,
        end_day: days.last.day,
        minutes: total,
        category_minutes: category_minutes
      }
    end
  end

  def weekly_date_ranges
    first_monday = @month.beginning_of_month.beginning_of_week(:monday)
    last_sunday = @month.end_of_month.end_of_week(:monday)

    (first_monday..last_sunday).each_slice(7).filter_map do |week|
      days = week.select { |d| d.month == @month.month }
      days.presence
    end
  end

  def build_category_totals(daily_logs)
    daily_logs
      .flat_map(&:learning_items)
      .reject { |i| i.duration_minutes.nil? }
      .group_by(&:category)
      .transform_values { |items| items.sum(&:duration_minutes) }
      .sort_by { |_, v| -v }
      .to_h
  end

  def calc_weekly_minutes
    monday = Time.zone.today.beginning_of_week
    current_user.daily_logs
                .where(date: monday..Time.zone.today)
                .joins(:learning_items)
                .sum('learning_items.duration_minutes')
  end

  def calc_streak
    today = Time.zone.today
    dates = current_user.daily_logs
                        .where(date: ..today)
                        .includes(:learning_items)
                        .order(date: :desc)
                        .filter_map { |log| log.date if log.recorded? }
    return 0 if dates.empty? || dates.first < today - 1

    base = dates.first
    count = 0
    dates.each_with_index do |date, i|
      break unless date == base - i.days

      count += 1
    end
    count
  end

  def load_monthly_goal
    @monthly_goal = current_user.monthly_goals.find_by(month: @month)
  end
end
