module TestConstants
  class User < ActiveRecord::Base
    belongs_to :employer
  end
end
