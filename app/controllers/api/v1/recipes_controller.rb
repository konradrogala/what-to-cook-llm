module Api
  module V1
    class RecipesController < ApplicationController
      def create
        Rails.logger.info "Current request count in controller: #{session[:api_requests_count]}"

        ingredients = params[:ingredients]

        if ingredients.blank? || ingredients.empty?
          render json: {
            error: "Ingredients cannot be empty",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :unprocessable_entity
          return
        end

        unless ingredients.is_a?(String) || ingredients.is_a?(Array)
          render json: {
            error: "Invalid ingredients format. Expected String or Array",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :unprocessable_entity
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
          render json: {
            error: "Failed to generate recipe",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :unprocessable_entity
        rescue Api::V1::RecipeParser::ParsingError => e
          render json: {
            error: "Failed to parse recipe",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :unprocessable_entity
        rescue Api::V1::RecipeCreator::CreationError => e
          render json: {
            error: "Failed to create recipe",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :unprocessable_entity
        rescue StandardError => e
          Rails.logger.error "Unexpected error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: {
            error: "An unexpected error occurred",
            remaining_requests: ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
          }, status: :internal_server_error
        end
      end
    end
  end
end
