module Api
  module V1
    class RecipeGenerator
      include Performable
      include InputSanitizer

      class GenerationError < StandardError; end

      def initialize(ingredients)
        @ingredients = ingredients
      end

      def perform
        validate_ingredients!
        check_feasibility!
        generate_recipe
      end

      private

      attr_reader :ingredients

      def validate_ingredients!
        @ingredients = sanitize_input(ingredients)
      rescue InputError => e
        case ingredients
        when String
          raise GenerationError, "Ingredients cannot be empty" if ingredients.strip.empty?
        when Array
          raise GenerationError, "Ingredients cannot be empty" if ingredients.empty?
        else
          raise GenerationError, "Invalid ingredients format. Expected String or Array"
        end
      end

      def check_feasibility!
        client = OpenAI::Client.new

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "user",
                content: I18n.t("api.v1.recipe_generator.prompts.feasibility", ingredients: ingredients_list)
              }
            ],
            temperature: 0.7,
            max_tokens: 10
          }
        )

        feasible = response.dig("choices", 0, "message", "content")&.strip&.downcase == "yes"
        raise GenerationError, "These ingredients cannot make a coherent dish" unless feasible
      rescue OpenAI::Error => e
        Rails.logger.error "OpenAI API error: #{e.message}"
        Rails.logger.error "Full error: #{e.inspect}"
        raise GenerationError, "Failed to generate recipe: #{e.message}"
      end

      def generate_recipe
        client = OpenAI::Client.new

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              {
                role: "user",
                content: I18n.t("api.v1.recipe_generator.prompts.base", ingredients: ingredients_list)
              }
            ],
            temperature: 0.7,
            max_tokens: 500
          }
        )

        response.dig("choices", 0, "message", "content")
      rescue OpenAI::Error => e
        Rails.logger.error "OpenAI API error: #{e.message}"
        Rails.logger.error "Full error: #{e.inspect}"
        raise GenerationError, "Failed to generate recipe: #{e.message}"
      end

      def ingredients_list
        ingredients.is_a?(Array) ? ingredients.join(", ") : ingredients
      end
    end
  end
end
