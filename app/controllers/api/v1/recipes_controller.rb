module Api
  module V1
    class RecipesController < ApplicationController
      include Api::V1::ErrorHandler

      def create
        Rails.logger.info "Current request count in controller: #{session[:api_requests_count]}"

        validate_ingredients!
        recipe = generate_recipe

        render json: {
          recipe: recipe,
          remaining_requests: remaining_requests
        }, status: :created
      rescue OpenAI::Error => e
        if e.message.include?("rate limit")
          render_error("API rate limit exceeded. Please try again in about an hour", :too_many_requests)
        else
          render_error("OpenAI API error: #{e.message}", :service_unavailable)
        end
      rescue Api::V1::RecipeGenerator::GenerationError => e
        render_error("Failed to generate recipe: #{e.message}", :unprocessable_entity)
      rescue Api::V1::RecipeParser::ParsingError => e
        render_error("Failed to parse recipe: #{e.message}", :unprocessable_entity)
      rescue Api::V1::RecipeCreator::CreationError => e
        render_error("Failed to create recipe: #{e.message}", :unprocessable_entity)
      rescue StandardError => e
        Rails.logger.error "Unexpected error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render_error("An unexpected error occurred", :internal_server_error)
      end

      private

      def validate_ingredients!
        if ingredients.blank? || ingredients.empty?
          render_error("Ingredients cannot be empty", :unprocessable_entity)
          return
        end

        unless ingredients.is_a?(String) || ingredients.is_a?(Array)
          render_error("Invalid ingredients format. Expected String or Array", :unprocessable_entity)
          nil
        end
      end

      def generate_recipe
        json_content = Api::V1::RecipeGenerator.perform(ingredients)
        recipe_attributes = Api::V1::RecipeParser.perform(json_content)
        Api::V1::RecipeCreator.perform(recipe_attributes)
      end

      def ingredients
        @ingredients ||= params[:ingredients]
      end

      def remaining_requests
        ApiRequestLimiter::MAX_REQUESTS - session[:api_requests_count].to_i
      end
    end
  end
end
