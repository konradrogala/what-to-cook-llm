class Api::V1::RecipesController < ApplicationController
  def create
    ingredients = params[:ingredients]

    if ingredients.blank? || ingredients.empty?
      render json: { error: "Ingredients cannot be empty" }, status: :unprocessable_entity
      return
    end

    begin
      json_content = Api::V1::RecipeGenerator.call(ingredients)
      recipe_attributes = Api::V1::RecipeParser.call(json_content)
      recipe = Api::V1::RecipeCreator.call(recipe_attributes)

      render json: recipe, status: :created
    rescue Api::V1::RecipeGenerator::GenerationError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue Api::V1::RecipeParser::ParsingError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue Api::V1::RecipeCreator::CreationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
