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

ActiveRecord::Schema[8.2].define(version: 2026_08_25_130000) do
  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "custom_styles"
    t.string "join_code", null: false
    t.string "name", null: false
    t.json "settings"
    t.integer "singleton_guard", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["singleton_guard"], name: "index_accounts_on_singleton_guard", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agents", force: :cascade do |t|
    t.string "api_token"
    t.datetime "created_at", null: false
    t.datetime "last_active_at"
    t.string "mcp_session_id"
    t.string "model", null: false
    t.string "name", null: false
    t.string "program", null: false
    t.integer "project_id", null: false
    t.integer "status", default: 0, null: false
    t.text "task_description"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_agents_on_api_token", unique: true
    t.index ["mcp_session_id"], name: "index_agents_on_mcp_session_id"
    t.index ["project_id", "name"], name: "index_agents_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_agents_on_project_id"
    t.index ["status"], name: "index_agents_on_status"
  end

  create_table "approval_request_actions", force: :cascade do |t|
    t.string "action"
    t.integer "actor_id"
    t.string "actor_type"
    t.integer "approval_request_id"
    t.datetime "created_at", null: false
    t.text "note"
    t.datetime "updated_at", null: false
  end

  create_table "approval_requests", force: :cascade do |t|
    t.integer "agent_id"
    t.datetime "created_at", null: false
    t.integer "message_id"
    t.json "payload"
    t.string "request_type"
    t.datetime "requested_at"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.integer "room_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["requested_at"], name: "index_approval_requests_on_requested_at"
    t.index ["room_id", "status", "requested_at"], name: "index_approval_requests_on_room_id_and_status_and_requested_at"
    t.index ["room_id"], name: "index_approval_requests_on_room_id"
    t.index ["status"], name: "index_approval_requests_on_status"
  end

  create_table "attention_items", force: :cascade do |t|
    t.boolean "ai_confirm", default: false, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "due_at"
    t.text "meta_text"
    t.boolean "overdue", default: false, null: false
    t.integer "project_id"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.integer "room_id"
    t.integer "source_id"
    t.string "source_type"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["due_at"], name: "index_attention_items_on_due_at"
    t.index ["project_id", "status", "due_at"], name: "index_attention_items_on_project_id_and_status_and_due_at"
    t.index ["project_id"], name: "index_attention_items_on_project_id"
    t.index ["status"], name: "index_attention_items_on_status"
  end

  create_table "bans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["ip_address"], name: "index_bans_on_ip_address"
    t.index ["user_id"], name: "index_bans_on_user_id"
  end

  create_table "boosts", force: :cascade do |t|
    t.integer "booster_id", null: false
    t.string "content", limit: 16, null: false
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booster_id"], name: "index_boosts_on_booster_id"
    t.index ["message_id"], name: "index_boosts_on_message_id"
  end

  create_table "file_reservations", force: :cascade do |t|
    t.integer "agent_id", null: false
    t.datetime "created_at", null: false
    t.boolean "exclusive", default: true, null: false
    t.datetime "expires_at", null: false
    t.json "patterns", default: [], null: false
    t.integer "project_id", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_file_reservations_on_agent_id"
    t.index ["expires_at"], name: "index_file_reservations_on_expires_at"
    t.index ["project_id", "expires_at"], name: "index_file_reservations_on_project_id_and_expires_at"
    t.index ["project_id"], name: "index_file_reservations_on_project_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "connected_at"
    t.integer "connections", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "involvement", default: "mentions"
    t.datetime "last_read_at"
    t.integer "participant_id", null: false
    t.string "participant_type", null: false
    t.integer "room_id", null: false
    t.datetime "unread_at"
    t.datetime "updated_at", null: false
    t.index ["last_read_at"], name: "index_memberships_on_last_read_at"
    t.index ["participant_id"], name: "index_memberships_on_participant_id"
    t.index ["participant_type", "participant_id"], name: "index_memberships_on_participant_type_and_participant_id"
    t.index ["room_id", "created_at"], name: "index_memberships_on_room_id_and_created_at"
    t.index ["room_id", "participant_type", "participant_id"], name: "index_memberships_on_room_and_participant", unique: true
    t.index ["room_id"], name: "index_memberships_on_room_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "client_message_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.integer "creator_id", null: false
    t.string "creator_type", null: false
    t.integer "room_id", null: false
    t.boolean "system", default: false, null: false
    t.string "system_type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["creator_type", "creator_id"], name: "index_messages_on_creator_type_and_creator_id"
    t.index ["room_id"], name: "index_messages_on_room_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "path", null: false
    t.boolean "private", default: false, null: false
    t.string "short_code"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_projects_on_path", unique: true
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["endpoint", "p256dh_key", "auth_key"], name: "idx_on_endpoint_p256dh_key_auth_key_7553014576"
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "room_ai_activity_states", force: :cascade do |t|
    t.integer "agent_id"
    t.datetime "created_at", null: false
    t.integer "room_id"
    t.datetime "started_at"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "agent_id"], name: "index_room_ai_activity_states_on_room_id_and_agent_id", unique: true
    t.index ["room_id"], name: "index_room_ai_activity_states_on_room_id"
    t.index ["updated_at"], name: "index_room_ai_activity_states_on_updated_at"
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.text "description"
    t.string "name"
    t.boolean "private", default: false, null: false
    t.integer "project_id"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_rooms_on_archived_at"
    t.index ["project_id", "type"], name: "index_rooms_on_project_id_and_type"
    t.index ["project_id"], name: "index_rooms_on_project_id"
  end

  create_table "searches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "query", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.string "bot_token"
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email_address"
    t.string "job_title"
    t.string "name", null: false
    t.string "password_digest"
    t.json "preferences"
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["bot_token"], name: "index_users_on_bot_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_webhooks_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agents", "projects"
  add_foreign_key "approval_request_actions", "approval_requests"
  add_foreign_key "approval_requests", "agents"
  add_foreign_key "approval_requests", "messages"
  add_foreign_key "approval_requests", "rooms"
  add_foreign_key "approval_requests", "users", column: "resolved_by_id"
  add_foreign_key "attention_items", "projects"
  add_foreign_key "attention_items", "rooms"
  add_foreign_key "attention_items", "users", column: "resolved_by_id"
  add_foreign_key "bans", "users"
  add_foreign_key "boosts", "messages"
  add_foreign_key "file_reservations", "agents"
  add_foreign_key "file_reservations", "projects"
  add_foreign_key "messages", "rooms"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "room_ai_activity_states", "agents"
  add_foreign_key "room_ai_activity_states", "rooms"
  add_foreign_key "rooms", "projects"
  add_foreign_key "searches", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "webhooks", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "message_search_index", "fts5", ["body", "tokenize=porter"]
end
