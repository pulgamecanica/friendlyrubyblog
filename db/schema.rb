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

ActiveRecord::Schema[8.0].define(version: 2026_04_09_173004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.bigint "document_id"
    t.string "type", null: false
    t.integer "position", default: 1
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "comments_count", default: 0, null: false
    t.integer "likes_count", default: 0, null: false
    t.bigint "language_id"
    t.boolean "interactive", default: false, null: false
    t.string "owner_type"
    t.bigint "owner_id"
    t.index ["data"], name: "index_blocks_on_data", using: :gin
    t.index ["document_id", "position"], name: "index_blocks_on_document_id_and_position"
    t.index ["document_id"], name: "index_blocks_on_document_id"
    t.index ["language_id"], name: "index_blocks_on_language_id"
    t.index ["owner_type", "owner_id"], name: "index_blocks_on_owner"
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
    t.integer "comments_count", default: 0, null: false
    t.integer "likes_count", default: 0, null: false
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

  create_table "game_player_states", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "player_id", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "player_id"], name: "index_game_player_states_on_game_id_and_player_id", unique: true
    t.index ["game_id"], name: "index_game_player_states_on_game_id"
    t.index ["player_id"], name: "index_game_player_states_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.bigint "submitter_id"
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.jsonb "source", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_games_on_deleted_at"
    t.index ["slug"], name: "index_games_on_slug", unique: true
    t.index ["status"], name: "index_games_on_status"
    t.index ["submitter_id"], name: "index_games_on_submitter_id"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.jsonb "raw_info", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_identities_on_player_id"
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
  end

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.string "extension", null: false
    t.string "executable_command"
    t.boolean "interactive", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["extension"], name: "index_languages_on_extension", unique: true
    t.index ["name"], name: "index_languages_on_name", unique: true
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

  create_table "page_views", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "ip_address"
    t.string "country"
    t.string "city"
    t.string "device"
    t.string "browser"
    t.string "os"
    t.text "referrer"
    t.string "next_page"
    t.text "user_agent"
    t.string "unique_visitor_id"
    t.string "session_id"
    t.datetime "visited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_page_views_on_country"
    t.index ["document_id"], name: "index_page_views_on_document_id"
    t.index ["ip_address"], name: "index_page_views_on_ip_address"
    t.index ["session_id"], name: "index_page_views_on_session_id"
    t.index ["unique_visitor_id"], name: "index_page_views_on_unique_visitor_id"
    t.index ["visited_at"], name: "index_page_views_on_visited_at"
  end

  create_table "play_sessions", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "player_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.integer "duration_ms"
    t.boolean "completed", default: false, null: false
    t.string "token", null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "started_at"], name: "index_play_sessions_on_game_id_and_started_at"
    t.index ["game_id"], name: "index_play_sessions_on_game_id"
    t.index ["player_id"], name: "index_play_sessions_on_player_id"
    t.index ["token"], name: "index_play_sessions_on_token", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "anon_token"
    t.string "display_name"
    t.string "intra_login"
    t.string "email"
    t.jsonb "preferences", default: {}, null: false
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["anon_token"], name: "index_players_on_anon_token", unique: true
    t.index ["email"], name: "index_players_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["intra_login"], name: "index_players_on_intra_login", unique: true, where: "(intra_login IS NOT NULL)"
  end

  create_table "scores", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.bigint "player_id", null: false
    t.bigint "play_session_id"
    t.bigint "value", null: false
    t.jsonb "meta", default: {}, null: false
    t.datetime "achieved_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "achieved_at"], name: "index_scores_on_game_id_and_achieved_at"
    t.index ["game_id", "player_id"], name: "index_scores_on_game_id_and_player_id"
    t.index ["game_id", "value"], name: "index_scores_on_game_id_and_value"
    t.index ["game_id"], name: "index_scores_on_game_id"
    t.index ["play_session_id"], name: "index_scores_on_play_session_id"
    t.index ["player_id"], name: "index_scores_on_player_id"
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

  # Solid Cache / Cable / Queue tables live in the primary database so a single
  # `db:prepare` (one DATABASE_URL) provisions everything. See config/cache.yml,
  # config/cable.yml and config/environments/production.rb (solid_queue -> :primary).
  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", limit: 1024, null: false
    t.binary "value", limit: 536870912, null: false
    t.datetime "created_at", null: false
    t.integer "key_hash", limit: 8, null: false
    t.integer "byte_size", limit: 4, null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.binary "payload", limit: 536870912, null: false
    t.datetime "created_at", null: false
    t.integer "channel_hash", limit: 8, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "documents"
  add_foreign_key "blocks", "languages"
  add_foreign_key "document_tags", "documents"
  add_foreign_key "document_tags", "tags"
  add_foreign_key "documents", "authors"
  add_foreign_key "documents", "series"
  add_foreign_key "game_player_states", "games"
  add_foreign_key "game_player_states", "players"
  add_foreign_key "games", "players", column: "submitter_id"
  add_foreign_key "identities", "players"
  add_foreign_key "page_views", "documents"
  add_foreign_key "play_sessions", "games"
  add_foreign_key "play_sessions", "players"
  add_foreign_key "scores", "games"
  add_foreign_key "scores", "play_sessions"
  add_foreign_key "scores", "players"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
