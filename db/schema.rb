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

ActiveRecord::Schema[7.0].define(version: 2022_12_09_161518) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.integer "purpose"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_id", "record_type"], name: "index_active_storage_attachments_on_record_id_and_record_type"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.integer "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    t.index ["blob_id"], name: "index_active_storage_variant_records_on_blob_id"
  end

  create_table "advisor_theses", id: false, force: :cascade do |t|
    t.integer "thesis_id"
    t.integer "advisor_id"
    t.index ["advisor_id"], name: "index_advisor_theses_on_advisor_id"
    t.index ["thesis_id"], name: "index_advisor_theses_on_thesis_id"
  end

  create_table "advisors", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "authors", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "thesis_id", null: false
    t.boolean "graduation_confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "proquest_allowed"
    t.index ["thesis_id"], name: "index_authors_on_thesis_id"
    t.index ["user_id"], name: "index_authors_on_user_id"
  end

  create_table "copyrights", force: :cascade do |t|
    t.text "holder", null: false
    t.boolean "display_to_author", null: false
    t.text "display_description", null: false
    t.text "statement_dspace", null: false
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "degree_theses", id: false, force: :cascade do |t|
    t.integer "thesis_id"
    t.integer "degree_id"
    t.index ["degree_id"], name: "index_degree_theses_on_degree_id"
    t.index ["thesis_id"], name: "index_degree_theses_on_thesis_id"
  end

  create_table "degree_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_degree_types_on_name", unique: true
  end

  create_table "degrees", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code_dw", null: false
    t.string "name_dw"
    t.string "abbreviation"
    t.string "name_dspace"
    t.integer "degree_type_id"
    t.index ["code_dw"], name: "index_degrees_on_code_dw", unique: true
    t.index ["degree_type_id"], name: "index_degrees_on_degree_type_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "department_theses", force: :cascade do |t|
    t.integer "thesis_id"
    t.integer "department_id"
    t.boolean "primary", default: false, null: false
    t.index ["department_id", "thesis_id"], name: "department_and_thesis", unique: true
    t.index ["department_id"], name: "index_department_theses_on_department_id"
    t.index ["thesis_id"], name: "index_department_theses_on_thesis_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name_dw", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code_dw", default: "", null: false
    t.string "name_dspace"
    t.string "authority_key_dspace"
    t.index ["code_dw"], name: "index_departments_on_code_dw", unique: true
    t.index ["name_dw"], name: "index_departments_on_name_dw"
  end

  create_table "hold_sources", force: :cascade do |t|
    t.text "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "holds", force: :cascade do |t|
    t.integer "thesis_id", null: false
    t.date "date_requested", null: false
    t.date "date_start", null: false
    t.date "date_end", null: false
    t.integer "hold_source_id", null: false
    t.string "case_number"
    t.integer "status", null: false
    t.text "processing_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hold_source_id"], name: "index_holds_on_hold_source_id"
    t.index ["thesis_id"], name: "index_holds_on_thesis_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.text "display_description", null: false
    t.text "license_type", null: false
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "proquest_export_batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "registrars", force: :cascade do |t|
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_registrars_on_user_id"
  end

  create_table "submission_information_packages", force: :cascade do |t|
    t.datetime "preserved_at", precision: nil
    t.integer "preservation_status", default: 0, null: false
    t.string "bag_declaration"
    t.string "bag_name"
    t.text "manifest"
    t.text "metadata"
    t.integer "thesis_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["thesis_id"], name: "index_submission_information_packages_on_thesis_id"
  end

  create_table "submitters", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "department_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_submitters_on_department_id"
    t.index ["user_id"], name: "index_submitters_on_user_id"
  end

  create_table "theses", force: :cascade do |t|
    t.string "title"
    t.text "abstract"
    t.date "grad_date", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "processor_note"
    t.text "author_note"
    t.boolean "files_complete", default: false, null: false
    t.boolean "metadata_complete", default: false, null: false
    t.string "publication_status", default: "Not ready for publication", null: false
    t.string "coauthors"
    t.integer "copyright_id"
    t.integer "license_id"
    t.string "dspace_handle"
    t.boolean "issues_found", default: false, null: false
    t.integer "authors_count"
    t.integer "proquest_exported", default: 0, null: false
    t.integer "proquest_export_batch_id"
    t.index ["copyright_id"], name: "index_theses_on_copyright_id"
    t.index ["license_id"], name: "index_theses_on_license_id"
    t.index ["proquest_export_batch_id"], name: "index_theses_on_proquest_export_batch_id"
  end

  create_table "transfers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "department_id", null: false
    t.date "grad_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.integer "files_count", default: 0, null: false
    t.integer "unassigned_files_count", default: 0, null: false
    t.index ["department_id"], name: "index_transfers_on_department_id"
    t.index ["user_id"], name: "index_transfers_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "uid", null: false
    t.string "email", null: false
    t.boolean "admin", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "role", default: "basic"
    t.string "given_name"
    t.string "surname"
    t.string "kerberos_id", null: false
    t.string "display_name", null: false
    t.string "middle_name"
    t.string "preferred_name"
    t.string "orcid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["kerberos_id"], name: "index_users_on_kerberos_id", unique: true
    t.index ["orcid"], name: "index_users_on_orcid", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 1073741823
    t.text "object_changes", limit: 1073741823
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authors", "theses"
  add_foreign_key "authors", "users"
  add_foreign_key "degrees", "degree_types"
  add_foreign_key "holds", "hold_sources"
  add_foreign_key "holds", "theses"
  add_foreign_key "registrars", "users"
  add_foreign_key "submission_information_packages", "theses"
  add_foreign_key "submitters", "departments"
  add_foreign_key "submitters", "users"
  add_foreign_key "transfers", "departments"
  add_foreign_key "transfers", "users"
end
