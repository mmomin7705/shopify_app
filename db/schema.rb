
ActiveRecord::Schema[8.0].define(version: 2025_01_28_030810) do
  enable_extension "pg_catalog.plpgsql"

  create_table "shops", force: :cascade do |t|
    t.string "shop", null: false
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "scopes"
    t.datetime "expires_at"
    t.index ["shop"], name: "index_shops_on_shop", unique: true
  end
end
