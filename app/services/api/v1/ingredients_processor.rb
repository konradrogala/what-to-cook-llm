module Api
  module V1
    class IngredientsProcessor
      include Performable

      class ProcessingError < StandardError; end

      def initialize(ingredients)
        @ingredients = ingredients
      end

      def perform
        process_ingredients
      end

      private

      attr_reader :ingredients

      def process_ingredients
        case ingredients
        when String
          ingredients.split(",").map(&:strip)
        when Array
          ingredients.map(&:to_s).map(&:strip)
        else
          raise ProcessingError, "Invalid ingredients format. Expected String or Array"
        end
      end
    end
  end
end
