module Api
  module V1
    class RecipeGenerator
      include Performable
      include InputSanitizer

      class GenerationError < StandardError; end

      def initialize(ingredients)
        @ingredients = sanitize_input(ingredients)
      rescue InputError => e
        raise GenerationError, "Invalid ingredients input: #{e.message}"
      end

      def perform
        check_feasibility!
        generate_recipe
      end

      private

      attr_reader :ingredients

      def check_feasibility!
        client = OpenAI::Client.new
        Rails.logger.info "OpenAI client initialized"

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
        Rails.logger.info "Successfully received response from OpenAI API"
        Rails.logger.debug "Response: #{response.inspect}"

        feasible = response.dig("choices", 0, "message", "content")&.strip&.downcase == "yes"
        raise GenerationError, "These ingredients cannot make a coherent dish" unless feasible
      rescue OpenAI::Error => e
        Rails.logger.error "OpenAI API error: #{e.message}"
        Rails.logger.error "Full error: #{e.inspect}"
        raise GenerationError, "Failed to generate recipe: #{e.message}"
      end

      def generate_recipe
        client = OpenAI::Client.new
        Rails.logger.info "OpenAI client initialized"

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
        Rails.logger.info "Successfully received response from OpenAI API"
        Rails.logger.debug "Response: #{response.inspect}"

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
