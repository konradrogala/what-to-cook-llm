module Api
  module V1
    class RecipesController < ApplicationController
      include Api::V1::ErrorHandler

      def create
        counter = Api::V1::RequestCounter.new(session)
        counter.reset_if_expired
        Rails.logger.info "Current request count in controller: #{counter.current_count}"

        # Check if limit is exceeded before processing
        if counter.limit_exceeded?
          render json: {
            error: "Rate limit exceeded. Please try again later.",
            remaining_requests: counter.remaining_requests
          }, status: :too_many_requests
          return
        end

        validate_ingredients!
        recipe = generate_recipe

        # Increment counter after successful request
        counter.increment
        Rails.logger.info "Incremented count to: #{counter.current_count}"

        # Check if this was the last available request
        is_limit_reached = counter.limit_exceeded?

        render json: {
          recipe: recipe,
          remaining_requests: counter.remaining_requests,
          limit_reached: is_limit_reached,
          message: is_limit_reached ? "You have reached the maximum number of requests for this session." : nil
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
