class Shop < ApplicationRecord
  validates :shop, presence: true, uniqueness: true

  def active?
    access_token.present? && !token_expired?
  end

  def token_expired?
    expires_at.present? && expires_at < Time.current
  end

  def shop_name
    shop.split('.')[0]
  end
end
