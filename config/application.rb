require_relative "boot"

require "rails/all"
Bundler.require(*Rails.groups)

module ShopifyApp
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.middleware.use ActionDispatch::Session::CookieStore, key: '_shopify_app_session'
  end
end
