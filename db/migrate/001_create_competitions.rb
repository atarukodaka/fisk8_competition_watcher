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

      t.string :ranking
      t.string :tss
      t.string :tes
      t.string :pcs
      
      t.belongs_to :category
    end

    create_table :segment_results do |t|
      t.string :ranking

      t.string :skater_name
      t.string :skater_nation
      t.integer :skater_isu_number
      t.references :skater

      t.string :tss
      t.string :tes
      t.string :pcs

      t.string :components_ss
      t.string :components_tr
      t.string :components_pe
      t.string :components_ch
      t.string :components_in
      
      t.string :deductions
      t.string :starting_number

      t.belongs_to :segment
    end
  end
end
