module Api
  module V1
    class RecipeParser
      include Performable

      class ParsingError < StandardError; end

      def initialize(json_content)
        @json_content = json_content
      end

      def perform
        recipe_data = parse_json
        validate_recipe!(recipe_data)
        check_feasibility!(recipe_data)
        extract_recipe_attributes(recipe_data)
      end

      private

      attr_reader :json_content

      def parse_json
        JSON.parse(json_content)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse recipe data: #{e.message}"
        raise ParsingError, "Invalid recipe format: #{e.message}"
      end

      def validate_recipe!(recipe_data)
        Api::V1::RecipeValidator.perform(recipe_data)
      rescue Api::V1::RecipeValidator::ValidationError => e
        Rails.logger.error "Recipe validation failed: #{e.message}"
        raise ParsingError, "Invalid recipe format: #{e.message}"
      end

      def check_feasibility!(recipe_data)
        suggestions = Api::V1::RecipeFeasibilityChecker.perform(recipe_data)
        if suggestions.any?
          Rails.logger.info "Recipe feasible with suggestions: #{suggestions}"
          recipe_data["suggestions"] = suggestions
        end
      rescue Api::V1::RecipeFeasibilityChecker::FeasibilityError => e
        Rails.logger.error "Recipe feasibility check failed: #{e.message}"
        raise ParsingError, e.message
      end

      def extract_recipe_attributes(recipe_data)
        {
          title: recipe_data["title"],
          ingredients: recipe_data["ingredients"],
          instructions: recipe_data["instructions"],
          suggestions: recipe_data["suggestions"]
        }
      end
    end
  end
end
