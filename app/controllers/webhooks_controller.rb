class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_webhook_hmac, only: [:product_update]

  def product_update
    product_data = params[:product]

    if product_data.blank?
      render plain: "No product data received", status: :bad_request
      return
    end
    SyncProductsJob.perform_later(params[:source_shop_id], params[:target_shop_id], [product_data['id']])

    head :ok
  end
  private

  def verify_webhook_hmac
    hmac_header = request.headers['X-Shopify-Hmac-SHA256']
    calculated_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest('sha256', ENV['SHOPIFY_API_SECRET'], request.raw_post)
    )

    unless ActiveSupport::SecurityUtils.secure_compare(hmac_header, calculated_hmac)
      render plain: "Unauthorized", status: :unauthorized
    end
  end
end
