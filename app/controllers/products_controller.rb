class ProductsController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :verify_shop_session

  def sync
    validate_sync_params

    product_ids = params[:product_ids]
    target_shop_id = params[:target_shop_id]
    source_shop_id = session[:shop_id]

    SyncProductsJob.perform_later(source_shop_id, target_shop_id, product_ids)

    render json: {
      status: 'success',
      message: 'Product sync initiated successfully'
    }
  rescue => e
    Rails.logger.error("Sync error: #{e.message}")
    render json: {
      status: 'error',
      message: 'Failed to initiate product sync'
    }, status: :unprocessable_entity
  end

  private

  def verify_shop_session
    unless session[:shop_id].present?
      render json: {
        status: 'error',
        message: 'Shop authentication required'
      }, status: :unauthorized
    end
  end

  def validate_sync_params
    unless params[:product_ids].present? && params[:target_shop_id].present?
      raise "Missing required parameters"
    end

    unless Shop.exists?(params[:target_shop_id])
      raise "Target shop not found"
    end
  end
end
