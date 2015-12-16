# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 2) do

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "surname"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name"
    t.string   "entry_url"
    t.string   "result_url"
    t.integer  "isu_category_number"
    t.integer  "competition_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "category_results", force: :cascade do |t|
    t.integer  "ranking"
    t.string   "skater_name"
    t.string   "skater_nation"
    t.integer  "skater_isu_number"
    t.integer  "skater_id"
    t.float    "points",            default: 0.0
    t.integer  "sp_ranking"
    t.integer  "fs_ranking"
    t.integer  "category_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "competitions", force: :cascade do |t|
    t.string   "key"
    t.string   "name"
    t.string   "shortname"
    t.string   "season"
    t.string   "competition_class"
    t.string   "competition_type"
    t.string   "hosted_by"
    t.string   "country"
    t.string   "city"
    t.date     "starting_date",     default: '1970-01-01'
    t.date     "ending_date",       default: '1970-01-01'
    t.string   "timezone",          default: "UST"
    t.string   "site_url"
    t.string   "comment"
    t.string   "parser",            default: "ISU"
    t.string   "updating"
    t.string   "status"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "entries", force: :cascade do |t|
    t.integer "number"
    t.integer "skater_id"
    t.integer "category_id"
  end

  create_table "segment_results", force: :cascade do |t|
    t.string   "ranking"
    t.string   "skater_name"
    t.string   "skater_nation"
    t.integer  "skater_isu_number"
    t.integer  "skater_id"
    t.string   "tss"
    t.string   "tes"
    t.string   "pcs"
    t.string   "components_ss"
    t.string   "components_tr"
    t.string   "components_pe"
    t.string   "components_ch"
    t.string   "components_in"
    t.string   "deductions"
    t.string   "starting_number"
    t.integer  "segment_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "segments", force: :cascade do |t|
    t.integer  "number"
    t.string   "name"
    t.string   "segment_type"
    t.datetime "starting_time", default: '1970-01-01 00:00:00'
    t.string   "order_url"
    t.string   "score_url"
    t.integer  "category_id"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  create_table "skaters", force: :cascade do |t|
    t.string   "name"
    t.integer  "isu_number"
    t.string   "nation"
    t.string   "category"
    t.integer  "ws_ranking"
    t.integer  "ws_points"
    t.float    "pb_total_score",              default: 0.0
    t.integer  "pb_total_category_result_id"
    t.float    "pb_sp_score",                 default: 0.0
    t.integer  "pb_sp_segment_result_id"
    t.float    "pb_fs_score",                 default: 0.0
    t.integer  "pb_fs_segment_result_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
  end

  create_table "skating_orders", force: :cascade do |t|
    t.string   "starting_number"
    t.string   "skater_name"
    t.string   "skater_nation"
    t.integer  "skater_isu_number"
    t.integer  "skater_id"
    t.string   "group"
    t.integer  "segment_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

end
