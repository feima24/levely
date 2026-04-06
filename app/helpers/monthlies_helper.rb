module MonthliesHelper
  def calendar_weeks(month)
    first = month.beginning_of_month.beginning_of_week(:sunday)
    last  = month.end_of_month.end_of_week(:sunday)
    (first..last).each_slice(7).to_a
  end

  def dot_level(minutes)
    if minutes.nil?
      :none    # 記録なし → ドットなし
    elsif minutes.zero?
      :weak    # 本文のみ（時間未入力）→ 薄いドット
    else
      :strong  # 時間あり → 濃いドット
    end
  end

  def calendar_cell_class(day, month)
    classes = []
    classes << 'other-month' if day.month != month.month
    classes << 'today'       if day == Time.zone.today
    classes << 'future'      if day > Time.zone.today
    classes.join(' ')
  end
end
