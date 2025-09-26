# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_26_231859) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "authors", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_authors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_authors_on_reset_password_token", unique: true
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "type", null: false
    t.integer "position", default: 1
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data"], name: "index_blocks_on_data", using: :gin
    t.index ["document_id", "position"], name: "index_blocks_on_document_id_and_position"
    t.index ["document_id"], name: "index_blocks_on_document_id"
  end

  create_table "comments", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.string "name"
    t.string "email"
    t.string "website"
    t.text "body_markdown"
    t.string "status", default: "visible", null: false
    t.string "actor_hash", null: false
    t.string "ip_hash"
    t.string "user_agent_hash"
    t.float "spam_score", default: 0.0, null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_hash"], name: "index_comments_on_actor_hash"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
  end

  create_table "document_tags", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "tag_id"], name: "index_document_tags_on_document_id_and_tag_id", unique: true
    t.index ["document_id"], name: "index_document_tags_on_document_id"
    t.index ["tag_id"], name: "index_document_tags_on_tag_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "kind"
    t.string "title"
    t.string "slug"
    t.text "description"
    t.bigint "author_id", null: false
    t.boolean "published"
    t.datetime "published_at"
    t.bigint "series_id", null: false
    t.integer "series_position"
    t.jsonb "metadata", default: {}, null: false
    t.text "search_text", default: "", null: false
    t.tsvector "search_vector"
    t.string "facet_languages", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_documents_on_author_id"
    t.index ["facet_languages"], name: "index_documents_on_facet_languages", using: :gin
    t.index ["search_vector"], name: "index_documents_on_search_vector", using: :gin
    t.index ["series_id"], name: "index_documents_on_series_id"
    t.index ["slug"], name: "index_documents_on_slug", unique: true
    t.index ["title"], name: "index_documents_on_title", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "likes", force: :cascade do |t|
    t.string "likable_type", null: false
    t.bigint "likable_id", null: false
    t.string "actor_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likable_type", "likable_id", "actor_hash"], name: "idx_likes_target_actor", unique: true
    t.index ["likable_type", "likable_id"], name: "index_likes_on_likable"
  end

  create_table "series", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_series_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "blocks", "documents"
  add_foreign_key "document_tags", "documents"
  add_foreign_key "document_tags", "tags"
  add_foreign_key "documents", "authors"
  add_foreign_key "documents", "series"
end
