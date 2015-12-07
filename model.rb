
## model
class Competition < ActiveRecord::Base
  has_many :categories, dependent: :destroy
end

class Category < ActiveRecord::Base
  has_many :segments, dependent: :destroy
end

class Segment < ActiveRecord::Base
  has_many :results, dependent: :destroy
end

class Skater < ActiveRecord::Base
  
end


class Entry < ActiveRecord::Base
#  has_one :skater
end

