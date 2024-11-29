module Api
  module V1
    class RecipeParser
      class ParsingError < StandardError; end

      def self.call(json_content)
        new(json_content).call
      end

      def initialize(json_content)
        @json_content = json_content
      end

      def call
        recipe_data = JSON.parse(json_content)
        Rails.logger.info "Successfully parsed recipe data"
        Rails.logger.debug "Recipe data: #{recipe_data.inspect}"

        {
          title: recipe_data["title"],
          ingredients: recipe_data["ingredients"].join("\n"),
          instructions: recipe_data["instructions"].join("\n")
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
