
## model
class Competition < ActiveRecord::Base
  has_many :entries, dependent: :destroy
end

class Entry < ActiveRecord::Base
#  has_one :skater
end

class Skater < ActiveRecord::Base
  
end

