class RecipeSerializer < ActiveModel::Serializer
  attributes :id, :title, :ingredients, :instructions, :created_at, :updated_at

  def ingredients
    object.ingredients.split("\n")
  end

  def instructions
    object.instructions.split("\n")
  end
end
