# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180130160813) do

  create_table "degree_theses", id: false, force: :cascade do |t|
    t.integer "thesis_id"
    t.integer "degree_id"
    t.index ["degree_id"], name: "index_degree_theses_on_degree_id"
    t.index ["thesis_id"], name: "index_degree_theses_on_thesis_id"
  end

  create_table "degrees", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "departments_theses", id: false, force: :cascade do |t|
    t.integer "thesis_id"
    t.integer "department_id"
    t.index ["department_id"], name: "index_departments_theses_on_department_id"
    t.index ["thesis_id"], name: "index_departments_theses_on_thesis_id"
  end

  create_table "rights", force: :cascade do |t|
    t.text "statement", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "theses", force: :cascade do |t|
    t.string "title", null: false
    t.text "abstract", null: false
    t.date "grad_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "right_id"
    t.string "status", default: "active"
    t.index ["right_id"], name: "index_theses_on_right_id"
    t.index ["user_id"], name: "index_theses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "uid", null: false
    t.string "email", null: false
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "basic"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

end
