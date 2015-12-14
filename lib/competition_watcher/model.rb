
## model
class Competition < ActiveRecord::Base
  has_many :categories, dependent: :destroy
end

class Category < ActiveRecord::Base
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
  references :skater
end

class CategoryResult < ActiveRecord::Base
  belongs_to :category
  references :skater
end


class SegmentResult < ActiveRecord::Base
  belongs_to :segment
  references :skater
end

class Skater < ActiveRecord::Base
end

class Entry < ActiveRecord::Base
#  has_one :skater
end

