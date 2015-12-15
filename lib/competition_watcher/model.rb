
## model
class Competition < ActiveRecord::Base
  has_many :categories, dependent: :destroy
end

class Category < ActiveRecord::Base
  has_many :entries, dependent: :destroy
  has_many :segments, dependent: :destroy
  has_many :category_results, dependent: :destroy
  belongs_to :competition
end

class Segment < ActiveRecord::Base
  has_many :skating_orders, dependent: :destroy
  has_many :segment_results, dependent: :destroy

  belongs_to :category
end

class SkatingOrder < ActiveRecord::Base
  belongs_to :segment
  belongs_to :skater  # reference
end

class CategoryResult < ActiveRecord::Base
  belongs_to :category
  belongs_to :skater  # reference
end

class SegmentResult < ActiveRecord::Base
  belongs_to :segment
  #references :skater
  belongs_to :skater  # reference
end

class Entry < ActiveRecord::Base
  belongs_to :skater
  belongs_to :category
end
################################################################
class Skater < ActiveRecord::Base
  belongs_to :pb_total_competition, class_name: Competition
  belongs_to :pb_sp_competition, class_name: Competition
  belongs_to :pb_fs_competition, class_name: Competition
end

