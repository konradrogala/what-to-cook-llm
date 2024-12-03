module Api
  module V1
    class RecipeCreator
      include Performable

      class CreationError < StandardError; end

      def initialize(recipe_attributes)
        @recipe_attributes = recipe_attributes
      end

      def perform
        validate_attributes!
        recipe = Recipe.new(prepare_attributes)

        if recipe.save
          recipe
        else
          Rails.logger.error "Failed to save recipe: #{recipe.errors.full_messages.join(', ')}"
          raise CreationError, recipe.errors.full_messages.join(", ")
        end
      end

      private

      attr_reader :recipe_attributes

      def validate_attributes!
        if recipe_attributes.blank? || !recipe_attributes.is_a?(Hash)
          raise CreationError, "Invalid recipe attributes"
        end
      end

      def prepare_attributes
        {
          title: recipe_attributes[:title],
          ingredients: Array(recipe_attributes[:ingredients]).join("\n"),
          instructions: Array(recipe_attributes[:instructions]).join("\n")
        }
      end
    end
  end
end
