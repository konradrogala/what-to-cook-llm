module Api
  module V1
    class RecipeGenerator
      include Performable
      include ActionView::Helpers::SanitizeHelper

      class GenerationError < StandardError; end

      def initialize(ingredients)
        @ingredients = sanitize_ingredients(ingredients)
      end

      def perform
        check_feasibility!
        generate_recipe
      end

      private

      attr_reader :ingredients

      def sanitize_ingredients(ingredients)
        ingredients_array = case ingredients
        when String
          ingredients.split(",").map(&:strip)
        when Array
          ingredients.map(&:to_s).map(&:strip)
        else
          raise GenerationError, "Invalid ingredients format. Expected String or Array"
        end

        ingredients_array.map { |ingredient| sanitize(ingredient, tags: [], attributes: []) }
      end

      def check_feasibility!
        client = OpenAI::Client.new

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "user",
                content: I18n.t("api.v1.recipe_generator.prompts.feasibility", ingredients: ingredients)
              }
            ],
            temperature: 0.7,
            max_tokens: 10
          }
        )

        feasible = response.dig("choices", 0, "message", "content")&.strip&.downcase == "yes"
        raise GenerationError, "These ingredients cannot make a coherent dish" unless feasible
      rescue OpenAI::Error => e
        handle_openai_error(e)
      end

      def generate_recipe
        client = OpenAI::Client.new

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "user",
                content: I18n.t("api.v1.recipe_generator.prompts.base", ingredients: ingredients)
              }
            ],
            temperature: 0.7,
            max_tokens: 500
          }
        )

        response.dig("choices", 0, "message", "content")
      rescue OpenAI::Error => e
        handle_openai_error(e)
      end

      def handle_openai_error(e)
        Rails.logger.error "OpenAI API error: #{e.message}"
        Rails.logger.error "Full error: #{e.inspect}"
        raise GenerationError, "Failed to generate recipe: #{e.message}"
      end
    end
  end
end
