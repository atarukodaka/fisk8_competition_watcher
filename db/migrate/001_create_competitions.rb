class CreateCompetitions < ActiveRecord::Migration
  def change
    create_table :skaters do |t|
      t.string :name
      t.integer :isu_number
      t.string :nation
      t.string :category

      t.timestamp
    end

    create_table :competitions do |t|
      t.string :key
      t.string :name
      t.string :shortname
      t.string :season
      t.string :competition_class
      t.string :competition_type
      t.string :hosted_by
      t.string :country
      t.string :city
      t.date :starting_date
      t.date :ending_date
      t.string :timezone
      t.string :site_url
      t.string :comment

      t.string :parser
      t.string :updating
      t.string :status

      t.timestamp
    end

    create_table :categories do |t|
      t.string :name
      t.string :entry_url
      t.string :result_url

      t.belongs_to :competition
    end

    create_table :segments do |t|
      t.string :name
      t.datetime :starting_time
      t.string :order_url
      t.string :score_url

      t.belongs_to :category
    end
  end
end
