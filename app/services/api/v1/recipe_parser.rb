module Api
  module V1
    class RecipeParser
      include Performable

      class ParsingError < StandardError; end

      def initialize(json_content)
        @json_content = json_content
      end

      def perform
        recipe_data = JSON.parse(json_content)
        Rails.logger.info "Successfully parsed recipe data"
        Rails.logger.debug "Recipe data: #{recipe_data.inspect}"

        {
          title: recipe_data["title"],
          ingredients: recipe_data["ingredients"],
          instructions: recipe_data["instructions"]
        }
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse recipe data: #{e.message}"
        raise ParsingError, "Invalid recipe format: #{e.message}"
      end

      private

      attr_reader :json_content
    end
  end
end
