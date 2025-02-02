class AddColumnsToShops < ActiveRecord::Migration[8.0]
  def change
    change_column_null :shops, :shop, false

    add_column :shops, :scopes, :string
    add_column :shops, :expires_at, :datetime

    add_index :shops, :shop, unique: true, if_not_exists: true
  end
end
