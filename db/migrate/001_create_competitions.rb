class CreateCompetitions < ActiveRecord::Migration
  def change
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
      t.date :starting_date, default: Time.at(0)
      t.date :ending_date, default: Time.at(0)
      t.string :timezone, default: 'UST'
      t.string :site_url
      t.string :comment

      t.string :parser, default: 'ISU'
      t.string :updating
      t.string :status

      t.timestamps null: false
    end

    create_table :categories do |t|
      t.string :name
      t.string :entry_url
      t.string :result_url
      t.integer :isu_category_number

      t.belongs_to :competition
      t.timestamps null: false
    end

    create_table :entries do |t|
      t.integer :number
      t.belongs_to :skater
      t.belongs_to :category
    end

    create_table :segments do |t|
      t.string :name
      t.datetime :starting_time, default: Time.at(0)
      t.string :order_url
      t.string :score_url

      t.string :ranking
      t.string :tss
      t.string :tes
      t.string :pcs
      
      t.belongs_to :category
      t.timestamps null: false
    end

    create_table :skating_orders do |t|
      t.string :starting_number
      t.string :skater_name
      t.string :skater_nation
      t.integer :skater_isu_number
      t.references :skater
      t.string :group

      t.belongs_to :segment
      t.timestamps null: false
    end

    create_table :category_results do |t|
      t.string :ranking

      t.string :skater_name
      t.string :skater_nation
      t.integer :skater_isu_number
      t.references :skater

      t.string :points
      t.integer :sp_ranking
      t.integer :fs_ranking

      t.belongs_to :category
      t.timestamps null: false
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
      t.timestamps null: false
    end

    ################
    create_table :skaters do |t|
      t.string :name
      t.integer :isu_number
      t.string :nation
      t.string :category
      t.integer :ws_ranking
      t.integer :ws_points

      t.float :pb_total_score, default: 0.00
      t.integer :pb_total_competition_id
      t.float :pb_sp_score, default: 0.00
      t.integer :pb_sp_competition_id
      t.float :pb_fs_score, default: 0.00
      t.integer :pb_fs_competition_id

      t.timestamps null: false
    end


  end
end
