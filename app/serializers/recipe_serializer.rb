class RecipeSerializer < ActiveModel::Serializer
  attributes :id, :title, :ingredients, :instructions, :suggestions, :created_at

  def ingredients
    object.ingredients.split("\n")
  end

  def instructions
    object.instructions.split("\n")
  end

  def suggestions
    object.suggestions&.split("\n") || []
  end
end
