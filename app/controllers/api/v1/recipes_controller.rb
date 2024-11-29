class Api::V1::RecipesController < ApplicationController
  def create
    Rails.logger.info "Current request count in controller: #{session[:api_requests_count]}"

    ingredients = params[:ingredients]

    if ingredients.blank? || ingredients.empty?
      render json: { error: "Ingredients cannot be empty" }, status: :unprocessable_entity
      return
    end

    begin
      json_content = Api::V1::RecipeGenerator.perform(ingredients)
      recipe_attributes = Api::V1::RecipeParser.perform(json_content)
      recipe = Api::V1::RecipeCreator.perform(recipe_attributes)

      render json: {
        recipe: recipe,
        remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
      }, status: :created
    rescue Api::V1::RecipeGenerator::GenerationError => e
      render json: { error: e.message }, status: :service_unavailable
    rescue Api::V1::RecipeParser::ParsingError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue Api::V1::RecipeCreator::CreationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
