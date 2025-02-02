class AuthController < ApplicationController
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:callback]

  def install
    shop = params[:shop]

    if shop.blank? || !valid_shop_domain?(shop)
      return render plain: "Invalid or missing shop parameter", status: :bad_request
    end

    scopes = ['write_products', 'read_products']
    nonce = SecureRandom.hex(16)
    access_mode = 'online'

    session[:oauth_nonce] = nonce

    oauth_url = "https://#{shop}/admin/oauth/authorize?" + {
      client_id: ENV['SHOPIFY_API_KEY'],
      scope: scopes.join(','),
      redirect_uri: "#{ENV['APP_URL']}/auth/callback",
      state: nonce,
      'grant_options[]' => access_mode
    }.to_query

    session[:shop] = shop

    redirect_to oauth_url, allow_other_host: true
  end

  def callback
    unless valid_callback_request?
      render plain: "Invalid OAuth callback", status: :unauthorized
      return
    end

    shop = params[:shop]

    begin
      response = HTTP.post(
        "https://#{shop}/admin/oauth/access_token",
        form: {
          client_id: ENV['SHOPIFY_API_KEY'],
          client_secret: ENV['SHOPIFY_API_SECRET'],
          code: params[:code]
        }
      ).parse


      ActiveRecord::Base.transaction do
        shop_record = Shop.find_or_initialize_by(shop: shop)
        shop_record.update!(
          access_token: response['access_token'],
          scopes: response['scope'],
          expires_at: Time.now + 24.hours
        )
        session[:shop_id] = shop_record.id
        session[:shop] = shop
        session[:access_token] = response['access_token']

        register_webhooks(shop, response['access_token'])
      end
      redirect_to root_path(shop: shop)

    rescue => e
      Rails.logger.error("Callback error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render plain: "OAuth error occurred", status: :internal_server_error
    end
  end

  private

  def valid_shop_domain?(shop)
    shop.present? && shop.match?(/\A[a-zA-Z0-9][a-zA-Z0-9\-]*\.myshopify\.com\z/)
  end

  def valid_callback_request?
    return false unless params[:shop].present?

    return false unless params[:state].present? && params[:state] == session[:oauth_nonce]

    return false unless params[:hmac].present?

    parameters = params.to_unsafe_h.except(:controller, :action, :hmac)
    sorted_params = parameters.sort.map { |k, v| "#{k}=#{v}" }.join('&')
    calculated_hmac = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV['SHOPIFY_API_SECRET'],
      sorted_params
    )

    params[:hmac] == calculated_hmac
  end

  def register_webhooks(shop, access_token)
    client = HTTP.headers(
      'X-Shopify-Access-Token' => access_token,
      'Content-Type' => 'application/json'
    )

    response = client.post(
      "https://#{shop}/admin/api/2024-01/webhooks.json",
      json: {
        webhook: {
          topic: 'products/update',
          address: "#{ENV['APP_URL']}/webhooks/product_update",
          format: 'json'
        }
      }
    ).parse

    if response['errors']
      if response['errors']['address']&.first&.include?('already been taken')
        Rails.logger.info("Webhook already registered for products/update")
      else
        Rails.logger.error("Webhook registration error: #{response['errors']}")
      end
    else
      Rails.logger.info("Webhook registered successfully")
    end
  rescue => e
    Rails.logger.error("Failed to register webhook: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
