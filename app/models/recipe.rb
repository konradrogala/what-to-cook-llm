class Recipe < ApplicationRecord
  validates :ingredients, presence: true
  validates :instructions, presence: true
  validates :title, presence: true
end
