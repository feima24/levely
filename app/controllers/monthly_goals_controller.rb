class MonthlyGoalsController < ApplicationController
  def create
    month = Date.iso8601("#{params[:month]}-01")
    @goal = current_user.monthly_goals.build(month: month, **goal_params)

    if @goal.save
      render json: goal_json(@goal), status: :created
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    @goal = find_goal
    if @goal.update(goal_params)
      render json: goal_json(@goal)
    else
      render json: { errors: @goal.errors.full_messages }, status: :unprocessable_content
    end
  end

  def toggle
    @goal = find_goal
    num = params[:goal_number].to_i
    return head(:bad_request) unless (1..3).cover?(num)

    field = "completed#{num}"
    @goal.update!(field => !@goal.send(field))
    render json: goal_json(@goal)
  end

  private

  def find_goal
    month = Date.iso8601("#{params[:month]}-01")
    current_user.monthly_goals.find_by!(month: month)
  end

  def goal_params
    params.require(:monthly_goal).permit(:goal1, :goal2, :goal3)
  end

  def goal_json(goal)
    {
      month: goal.month.strftime('%Y-%m'),
      goal1: goal.goal1, goal2: goal.goal2, goal3: goal.goal3,
      completed1: goal.completed1, completed2: goal.completed2, completed3: goal.completed3,
      rank: goal.rank
    }
  end
end
