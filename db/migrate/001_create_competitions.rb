class CreateCompetitions < ActiveRecord::Migration
  def change
    create_table :skaters do |t|
      t.string :name
      t.integer :isu_num
      t.string :nation

      t.timestamp
    end

    create_table :competitions do |t|
      t.string :key
      t.string :name
      t.string :season
      t.string :competition_class
      t.string :hosted_by
      t.string :country
      t.string :city
      t.date :starting_date
      t.date :ending_date
      t.string :timezone
      t.string :site_url

      t.string :parser
      t.string :status

      t.timestamp
    end

    create_table :entries do |t|
      t.string :category
      t.string :number
      t.integer :skater_id

      t.timestamp
      t.belongs_to :competition
    end
  end
end
