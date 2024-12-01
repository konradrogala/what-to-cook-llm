class Api::V1::RecipesController < ApplicationController
  def create
    Rails.logger.info "Current request count in controller: #{session[:api_requests_count]}"

    ingredients = params[:ingredients]

    if ingredients.nil? || ingredients.blank? || (ingredients.is_a?(Array) && ingredients.empty?)
      render json: { error: "Ingredients cannot be empty" }, status: :unprocessable_entity
      return
    end

    unless ingredients.is_a?(String) || ingredients.is_a?(Array)
      render json: { error: "Invalid ingredients format. Expected String or Array" }, status: :unprocessable_entity
      return
    end

    begin
      json_content = Api::V1::RecipeGenerator.perform(ingredients)
      recipe_attributes = Api::V1::RecipeParser.perform(json_content)
      recipe = Api::V1::RecipeCreator.perform(recipe_attributes)

      render json: {
        recipe: recipe,
        remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count]
      }, status: :created
    rescue Api::V1::RecipeGenerator::GenerationError => e
      render json: { error: "Failed to generate recipe" }, status: :unprocessable_entity
    rescue Api::V1::RecipeParser::ParsingError => e
      render json: { error: "Failed to parse recipe" }, status: :unprocessable_entity
    rescue Api::V1::RecipeCreator::CreationError => e
      render json: { error: "Failed to create recipe" }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An unexpected error occurred" }, status: :internal_server_error
    end
  end
end
