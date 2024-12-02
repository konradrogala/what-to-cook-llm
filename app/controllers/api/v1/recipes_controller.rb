module Api
  module V1
    class RecipesController < ApplicationController
      include Api::V1::ErrorHandler

      def create
        counter = Api::V1::RequestCounter.new(session)
        Rails.logger.info "Current request count in controller: #{counter.current_count}"

        # Check if we've exceeded the limit before processing
        if counter.limit_exceeded?
          Rails.logger.warn "Rate limit exceeded in controller"
          return render_error(
            "Rate limit exceeded. Maximum #{ApiRequestLimiter::MAX_REQUESTS} requests per hour allowed.",
            :too_many_requests
          )
        end

        validate_ingredients!
        recipe = generate_recipe

        # Increment counter after successful request
        counter.increment
        Rails.logger.info "Incremented count to: #{counter.current_count}"

        render json: {
          recipe: recipe,
          remaining_requests: counter.remaining_requests
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
          raise Api::V1::RecipeGenerator::GenerationError, "Ingredients cannot be empty"
        end

        unless ingredients.is_a?(String) || ingredients.is_a?(Array)
          raise Api::V1::RecipeGenerator::GenerationError, "Invalid ingredients format. Expected String or Array"
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
    end
  end
end
