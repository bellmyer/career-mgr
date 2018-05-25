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

ActiveRecord::Schema.define(version: 2018_05_25_141505) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "coaches", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_coaches_on_name", unique: true
  end

  create_table "cohort_fellows", force: :cascade do |t|
    t.decimal "grade", precision: 8, scale: 4
    t.decimal "attendance", precision: 8, scale: 4
    t.integer "nps_response"
    t.integer "endorsement"
    t.integer "professionalism"
    t.integer "teamwork"
    t.text "feedback"
    t.integer "fellow_id"
    t.integer "cohort_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id", "fellow_id"], name: "index_cohort_fellows_on_cohort_id_and_fellow_id", unique: true
  end

  create_table "cohorts", force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_cohorts_on_course_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "phone"
    t.string "email"
    t.string "url"
    t.integer "contactable_id"
    t.string "contactable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contactable_id", "contactable_type"], name: "index_contacts_on_contactable_id_and_contactable_type", unique: true
  end

  create_table "courses", force: :cascade do |t|
    t.string "semester"
    t.integer "year"
    t.integer "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_courses_on_site_id"
  end

  create_table "employers", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_employers_on_name", unique: true
  end

  create_table "employment_statuses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_employment_statuses_on_name", unique: true
  end

  create_table "fellow_opportunities", force: :cascade do |t|
    t.date "secured_on"
    t.text "staff_notes"
    t.integer "fellow_id"
    t.integer "opportunity_id"
    t.integer "opportunity_stage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fellow_id", "opportunity_id"], name: "index_fellow_opportunities_on_fellow_id_and_opportunity_id", unique: true
    t.index ["opportunity_stage_id"], name: "index_fellow_opportunities_on_opportunity_stage_id"
  end

  create_table "fellows", force: :cascade do |t|
    t.string "key"
    t.string "first_name"
    t.string "last_name"
    t.integer "graduation_year"
    t.string "graduation_semester"
    t.integer "graduation_fiscal_year"
    t.text "interests_description"
    t.string "major"
    t.text "affiliations"
    t.decimal "gpa"
    t.string "linkedin_url"
    t.text "staff_notes"
    t.decimal "efficacy_score"
    t.integer "employment_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employment_status_id"], name: "index_fellows_on_employment_status_id"
    t.index ["key"], name: "index_fellows_on_key", unique: true
  end

  create_table "fellows_interests", id: false, force: :cascade do |t|
    t.bigint "fellow_id", null: false
    t.bigint "interest_id", null: false
    t.index ["fellow_id"], name: "index_fellows_interests_on_fellow_id"
    t.index ["interest_id"], name: "index_fellows_interests_on_interest_id"
  end

  create_table "industries", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_industries_on_name", unique: true
  end

  create_table "interests", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_interests_on_name", unique: true
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "opportunities", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "employer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employer_id"], name: "index_opportunities_on_employer_id"
  end

  create_table "opportunity_stages", force: :cascade do |t|
    t.string "name"
    t.decimal "probability", precision: 8, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_opportunity_stages_on_name", unique: true
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sites_on_name", unique: true
  end

end