class HomeController < ApplicationController
  before_action :ensure_shop_authenticated

  def index
    @products = fetch_products_from_shopify
    @target_shops = fetch_available_target_shops
  rescue => e
    Rails.logger.error("Error in HomeController#index: #{e.message}")
    @products = []
    @target_shops = []
  end

  private

  def ensure_shop_authenticated
    return if session[:shop_id].present?
    redirect_to "/auth/install?shop=#{params[:shop]}"
  end

  def fetch_products_from_shopify
    return [] unless current_shop&.active?

    client = build_shopify_client(current_shop)
    response = client.get(path: 'products.json')
    response.body['products'] || []
  rescue => e
    Rails.logger.error("Failed to fetch products: #{e.message}")
    []
  end

  def fetch_available_target_shops
    Shop.where.not(id: current_shop.id)
        .where.not(access_token: nil)
        .where('expires_at IS NULL OR expires_at > ?', Time.current)
        .map { |shop| [shop.shop_name, shop.id] }
  end

  def current_shop
    @current_shop ||= Shop.find_by(id: session[:shop_id])
  end

  def build_shopify_client(shop)
    session = ShopifyAPI::Auth::Session.new(
      shop: shop.shop,
      access_token: shop.access_token
    )
    ShopifyAPI::Clients::Rest::Admin.new(session: session)
  end
end
