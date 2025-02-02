class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def current_shop
    @current_shop ||= Shop.find_by(id: session[:shop_id]) if session[:shop_id]
  end

  helper_method :current_shop
end
