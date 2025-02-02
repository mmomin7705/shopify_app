class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops do |t|
      t.string :shop
      t.string :access_token

      t.timestamps
    end
  end
end
