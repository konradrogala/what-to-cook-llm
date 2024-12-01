module Api
  module V1
    class RecipesController < ApplicationController
      include Api::V1::ErrorHandler

      def create
        counter = Api::V1::RequestCounter.new(session)
        counter.reset_if_expired

        return limit_exceeded_message(counter) if counter.limit_exceeded?

        validate_ingredients!
        recipe = generate_recipe

        counter.increment

        is_limit_reached = counter.limit_exceeded?

        render json: {
          recipe: recipe,
          remaining_requests: counter.remaining_requests,
          limit_reached: is_limit_reached,
          message: is_limit_reached ? I18n.t("api.v1.recipes.messages.limit_reached") : nil
        }, status: :created

      rescue OpenAI::Error => e
        if e.message.include?("rate limit")
          render_error(I18n.t("api.v1.recipes.errors.openai_rate_limit"), :too_many_requests)
        else
          render_error(I18n.t("api.v1.recipes.errors.openai_error", message: e.message), :service_unavailable)
        end
      rescue Api::V1::RecipeGenerator::GenerationError => e
        render_error(I18n.t("api.v1.recipes.errors.recipe_generation", message: e.message), :unprocessable_entity)
      rescue Api::V1::RecipeParser::ParsingError => e
        render_error(I18n.t("api.v1.recipes.errors.recipe_parsing", message: e.message), :unprocessable_entity)
      rescue Api::V1::RecipeCreator::CreationError => e
        render_error(I18n.t("api.v1.recipes.errors.recipe_creation", message: e.message), :unprocessable_entity)
      rescue StandardError => e
        Rails.logger.error "Unexpected error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render_error(I18n.t("api.v1.recipes.errors.unexpected"), :internal_server_error)
      end

      private

      def limit_exceeded_message(counter)
        render json: {
          error: I18n.t("api.v1.recipes.errors.rate_limit"),
          remaining_requests: counter.remaining_requests
        }, status: :too_many_requests
      end

      def validate_ingredients!
        if ingredients.blank? || ingredients.empty?
          raise Api::V1::RecipeGenerator::GenerationError, I18n.t("api.v1.recipes.errors.empty_ingredients")
        end

        unless ingredients.is_a?(String) || ingredients.is_a?(Array)
          raise Api::V1::RecipeGenerator::GenerationError, I18n.t("api.v1.recipes.errors.invalid_ingredients_format")
        end
      end

      def ingredients
        @ingredients ||= params[:ingredients]
      end

      def generate_recipe
        json_content = Api::V1::RecipeGenerator.perform(ingredients)
        recipe_attributes = Api::V1::RecipeParser.perform(json_content)
        Api::V1::RecipeCreator.perform(recipe_attributes)
      end
    end
  end
end
