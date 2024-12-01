class Recipe < ApplicationRecord
  validates :title, presence: true
  validates :ingredients, presence: true
  validates :instructions, presence: true

  def ingredients_array
    self[:ingredients]&.split("\n") || []
  end

  def instructions_array
    self[:instructions]&.split("\n") || []
  end

  def as_json(options = {})
    super(options).merge(
      "ingredients" => ingredients_array,
      "instructions" => instructions_array
    )
  end
end
