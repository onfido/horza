module TestConstants
  class Employer < ActiveRecord::Base
    has_many :users
    has_many :sports_cars
  end
end