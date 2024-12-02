class Recipe < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3 }
  validates :ingredients, presence: true
  validates :instructions, presence: true

  def ingredients_array
    self[:ingredients]&.split("\n") || []
  end

  def instructions_array
    self[:instructions]&.split("\n") || []
  end

  def suggestions_array
    self[:suggestions]&.split("\n") || []
  end

  def as_json(options = {})
    super(options).merge(
      "ingredients" => ingredients_array,
      "instructions" => instructions_array,
      "suggestions" => suggestions_array
    )
  end
end
