ShopifyAPI::Context.setup(
  api_key: ENV['SHOPIFY_API_KEY'],
  api_secret_key: ENV['SHOPIFY_API_SECRET'],
  host_name: ENV['APP_URL'].gsub(/https?:\/\//, ''),
  scope: ENV['SCOPES'],
  is_embedded: true,
  is_private: false,
  api_version: "2024-01"
)
