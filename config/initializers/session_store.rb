Rails.application.config.session_store :cookie_store,
  key: '_shopify_app_session',
  expire_after: 24.hours,
  secure: true,
  same_site: :lax,
  httponly: true,
  domain: nil
