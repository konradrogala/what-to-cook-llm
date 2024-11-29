module Api
  module V1
    class RecipeCreator
      include Performable

      class CreationError < StandardError; end

      def initialize(recipe_attributes)
        @recipe_attributes = recipe_attributes
      end

      def perform
        recipe = Recipe.new(recipe_attributes)

        if recipe.save
          Rails.logger.info "Recipe saved successfully"
          recipe
        else
          Rails.logger.error "Failed to save recipe: #{recipe.errors.full_messages.join(', ')}"
          raise CreationError, recipe.errors.full_messages.join(", ")
        end
      end

      private

      attr_reader :recipe_attributes
    end
  end
end
