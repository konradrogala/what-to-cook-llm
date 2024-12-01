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
        client = OpenAI::Client.new
        Rails.logger.info "OpenAI client initialized"

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo-1106",
            messages: [{ role: "user", content: prompt }],
            response_format: { type: "json_object" }
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

      private

      attr_reader :ingredients

      def prompt
        "Generate a recipe using these ingredients: #{ingredients}. Format the response as JSON with the following structure: { title: string, ingredients: array of strings, instructions: array of strings }"
      end
    end
  end
end
