module Api
  module V1
    class RecipeFeasibilityChecker
      include Performable

      class FeasibilityError < StandardError; end

      def initialize(recipe_data)
        @recipe_data = recipe_data
      end

      def perform
        response = check_feasibility
        process_response(response)
      rescue OpenAI::Error => e
        handle_openai_error(e)
      end

      private

      attr_reader :recipe_data

      def check_feasibility
        client = OpenAI::Client.new

        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo-1106",
            messages: [ { role: "user", content: feasibility_prompt } ],
            response_format: { type: "json_object" }
          }
        )

        response.dig("choices", 0, "message", "content")
      end

      def process_response(response)
        result = JSON.parse(response)

        unless result["is_feasible"]
          issues = result["issues"].join(", ")
          raise FeasibilityError, "Recipe may not be feasible: #{issues}"
        end

        # Return any suggestions for improvement
        result["suggestions"]
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse feasibility check response: #{e.message}"
        raise FeasibilityError, "Invalid response format from feasibility check"
      end

      def handle_openai_error(error)
        if error.message.include?("rate limit")
          Rails.logger.warn "OpenAI rate limit exceeded during feasibility check"
          # Jeśli przekroczono limit, zakładamy że przepis jest ok
          # i zwracamy pustą listę sugestii
          []
        else
          Rails.logger.error "OpenAI API error during feasibility check: #{error.message}"
          raise FeasibilityError, "Failed to check recipe feasibility: #{error.message}"
        end
      end

      def feasibility_prompt
        <<~PROMPT
          Analyze this recipe and determine if it's feasible to cook. Consider:
          1. Are all necessary ingredients included?
          2. Are the instructions clear and complete?
          3. Are cooking times and temperatures appropriate?
          4. Are the steps in a logical order?
          5. Would this recipe actually work?

          Recipe to analyze:
          Title: #{recipe_data["title"]}

          Ingredients:
          #{recipe_data["ingredients"].join("\n")}

          Instructions:
          #{recipe_data["instructions"].join("\n")}

          Respond in JSON format:
          {
            "is_feasible": boolean,
            "issues": [
              "List any problems that would make this recipe difficult or impossible to cook"
            ],
            "suggestions": [
              "List any suggestions for improving the recipe"
            ]
          }
        PROMPT
      end
    end
  end
end
