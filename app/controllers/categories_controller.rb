class CategoriesController < ApplicationController
  def index
    @categories = current_user.categories.order(:name)
  end

  def update
    @category = current_user.categories.find(params.expect(:id))
    if @category.update(category_params)
      redirect_to categories_path, notice: '更新しました'
    else
      @categories = current_user.categories.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  private

  def category_params
    params.expect(category: [:name])
  end
end
