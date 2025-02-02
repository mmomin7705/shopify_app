class SyncProductsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(source_shop_id, target_shop_id, product_ids)
    @source_shop = Shop.find(source_shop_id)
    @target_shop = Shop.find(target_shop_id)

    validate_shops
    setup_shopify_context
    sync_products(product_ids)
  end

  private

  def validate_shops
    raise "Source shop token expired" if @source_shop.token_expired?
    raise "Target shop token expired" if @target_shop.token_expired?
    raise "Invalid source shop access token" unless @source_shop.access_token.present?
    raise "Invalid target shop access token" unless @target_shop.access_token.present?
  end

  def setup_shopify_context
    ShopifyAPI::Context.setup(
      api_key: ENV['SHOPIFY_API_KEY'],
      api_secret_key: ENV['SHOPIFY_API_SECRET'],
      host: ENV['APP_URL'],
      api_version: '2024-01',
      is_private: false,
      is_embedded: true
    )
  end

  def sync_products(product_ids)
    source_client = build_client(@source_shop)
    target_client = build_client(@target_shop)

    product_ids.each do |product_id|
      sync_single_product(product_id, source_client, target_client)
    end
  end

  def sync_single_product(product_id, source_client, target_client)
    source_product = fetch_source_product(product_id, source_client)
    return unless source_product

    create_or_update_product(source_product, target_client)
  rescue => e
    Rails.logger.error("Failed to sync product #{product_id}: #{e.message}")
    raise
  end

  def fetch_source_product(product_id, client)
    response = client.get(path: "products/#{product_id}.json")
    response.body['product']
  end

  def create_or_update_product(source_product, target_client)
    product_data = build_product_data(source_product)

    target_client.post(
      path: 'products.json',
      body: { product: product_data }
    )
  end

  def build_product_data(source_product)
    {
      title: source_product['title'],
      body_html: source_product['body_html'],
      vendor: source_product['vendor'],
      product_type: source_product['product_type'],
      status: source_product['status'],
      tags: source_product['tags'],
      variants: build_variants(source_product['variants']),
      options: source_product['options'],
      images: build_images(source_product['images'])
    }
  end

  def build_variants(source_variants)
    source_variants.map do |variant|
      {
        price: variant['price'],
        sku: variant['sku'],
        option1: variant['option1'],
        option2: variant['option2'],
        option3: variant['option3'],
        inventory_quantity: variant['inventory_quantity'],
        inventory_management: variant['inventory_management']
      }
    end
  end

  def build_images(source_images)
    source_images.map do |image|
      {
        src: image['src'],
        position: image['position'],
        alt: image['alt']
      }
    end
  end

  def build_client(shop)
    session = ShopifyAPI::Auth::Session.new(
      shop: shop.shop,
      access_token: shop.access_token
    )
    ShopifyAPI::Clients::Rest::Admin.new(session: session)
  end
end
