class HistoriesController < ApplicationController
  ITEMS_PER_PAGE = 100

  def index
    @page = params.fetch(:page, 1).to_i
    @daily_logs = current_user.daily_logs
                              .includes(learning_items: :category)
                              .order(date: :desc)
                              .offset((@page - 1) * ITEMS_PER_PAGE)
                              .limit(ITEMS_PER_PAGE)
  end
end
