class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?
  allow_browser versions: :modern

  # ログイン後のリダイレクト先
  def after_sign_in_path_for(_resource)
    monthly_path(Time.zone.today.strftime('%Y-%m'))
  end

  # ログアウト後のリダイレクト先
  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
