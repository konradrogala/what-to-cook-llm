class Recipe < ApplicationRecord
  validates :title, presence: true
  validates :ingredients, presence: true
  validates :instructions, presence: true

  def ingredients
    self[:ingredients]&.split("\n") || []
  end

  def instructions
    self[:instructions]&.split("\n") || []
  end
end
