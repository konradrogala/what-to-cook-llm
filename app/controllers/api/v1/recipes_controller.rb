module Api
  module V1
    class RecipesController < ApplicationController
      include Api::V1::ErrorHandler

      def create
        counter = Api::V1::RequestCounter.new(session)
        counter.reset_if_expired

        return limit_exceeded_message(counter) if counter.limit_exceeded?

        recipe = generate_recipe
        counter.increment

        is_limit_reached = counter.limit_exceeded?

        render json: {
          recipe: recipe,
          remaining_requests: counter.remaining_requests,
          limit_reached: is_limit_reached,
          message: is_limit_reached ? I18n.t("api.v1.recipes.messages.limit_reached") : nil
        }, status: :created
      end

      private

      def limit_exceeded_message(counter)
        render json: {
          error: I18n.t("api.v1.recipes.errors.rate_limit"),
          remaining_requests: counter.remaining_requests
        }, status: :too_many_requests
      end

      def recipe_params
        params.require(:ingredients)
        { ingredients: Api::V1::IngredientsProcessor.perform(params[:ingredients]) }
      end

      def generate_recipe
        json_response = Api::V1::RecipeGenerator.perform(recipe_params[:ingredients])
        recipe_attributes = Api::V1::RecipeParser.perform(json_response)
        Api::V1::RecipeCreator.perform(recipe_attributes)
      end
    end
  end
end
