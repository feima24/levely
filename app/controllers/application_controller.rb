class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?
  allow_browser versions: :modern

  def after_sign_in_path_for(_resource)
    monthly_path(Time.zone.today.strftime('%Y-%m'))
  end
end
