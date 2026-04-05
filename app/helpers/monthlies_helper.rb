module MonthliesHelper
  def calendar_weeks(month)
    first = month.beginning_of_month.beginning_of_week(:sunday)
    last  = month.end_of_month.end_of_week(:sunday)
    (first..last).each_slice(7).to_a
  end
end
