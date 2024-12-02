module Api
  module V1
    class RecipeValidator
      include Performable

      REQUIRED_FIELDS = %w[title ingredients instructions].freeze
      ARRAY_FIELDS = %w[ingredients instructions].freeze
      MIN_INGREDIENTS = 2
      MIN_INSTRUCTIONS = 2

      class ValidationError < StandardError; end

      def initialize(recipe_data)
        @recipe_data = recipe_data
      end

      def perform
        validate_structure!
        validate_required_fields!
        validate_array_fields!
        validate_content!
        
        true
      end

      private

      attr_reader :recipe_data

      def validate_structure!
        raise ValidationError, "Recipe data must be a hash" unless recipe_data.is_a?(Hash)
      end

      def validate_required_fields!
        missing_fields = REQUIRED_FIELDS - recipe_data.keys
        if missing_fields.any?
          raise ValidationError, "Missing required fields: #{missing_fields.join(', ')}"
        end
      end

      def validate_array_fields!
        ARRAY_FIELDS.each do |field|
          value = recipe_data[field]
          unless value.is_a?(Array)
            raise ValidationError, "#{field.capitalize} must be an array"
          end
        end
      end

      def validate_content!
        validate_title!
        validate_ingredients!
        validate_instructions!
      end

      def validate_title!
        title = recipe_data['title'].to_s
        if title.blank? || title.length < 3
          raise ValidationError, "Title must be at least 3 characters long"
        end
      end

      def validate_ingredients!
        ingredients = recipe_data['ingredients']
        if ingredients.length < MIN_INGREDIENTS
          raise ValidationError, "Recipe must have at least #{MIN_INGREDIENTS} ingredients"
        end

        ingredients.each do |ingredient|
          if ingredient.to_s.blank? || ingredient.to_s.length < 2
            raise ValidationError, "Each ingredient must be at least 2 characters long"
          end
        end
      end

      def validate_instructions!
        instructions = recipe_data['instructions']
        if instructions.length < MIN_INSTRUCTIONS
          raise ValidationError, "Recipe must have at least #{MIN_INSTRUCTIONS} instructions"
        end

        instructions.each do |instruction|
          if instruction.to_s.blank? || instruction.to_s.length < 10
            raise ValidationError, "Each instruction must be at least 10 characters long"
          end
        end
      end
    end
  end
end
