module Api
  module V1
    class IngredientsProcessor
      include Performable

      class ProcessingError < StandardError; end

      def initialize(ingredients)
        @ingredients = ingredients
      end

      def perform
        Rails.logger.info "Processing ingredients: #{ingredients.inspect}"

        processed = process_ingredients
        Rails.logger.info "Processed ingredients: #{processed.inspect}"

        processed
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
