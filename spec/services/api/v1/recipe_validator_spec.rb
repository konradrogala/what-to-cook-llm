require 'rails_helper'

RSpec.describe Api::V1::RecipeValidator do
  let(:valid_recipe_data) do
    {
      'title' => 'Spaghetti Bolognese',
      'ingredients' => ['spaghetti', 'ground beef', 'tomato sauce'],
      'instructions' => [
        'Boil the spaghetti according to package instructions',
        'Brown the ground beef in a large pan'
      ]
    }
  end

  subject { described_class.new(recipe_data) }

  context 'with valid recipe data' do
    let(:recipe_data) { valid_recipe_data }

    it 'returns true' do
      expect(subject.perform).to be true
    end
  end

  context 'with invalid recipe data' do
    context 'when data is not a hash' do
      let(:recipe_data) { 'not a hash' }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Recipe data must be a hash'
        )
      end
    end

    context 'when missing required fields' do
      let(:recipe_data) { valid_recipe_data.except('title') }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Missing required fields: title'
        )
      end
    end

    context 'when ingredients is not an array' do
      let(:recipe_data) { valid_recipe_data.merge('ingredients' => 'spaghetti') }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Ingredients must be an array'
        )
      end
    end

    context 'when instructions is not an array' do
      let(:recipe_data) { valid_recipe_data.merge('instructions' => 'cook it') }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Instructions must be an array'
        )
      end
    end

    context 'when title is too short' do
      let(:recipe_data) { valid_recipe_data.merge('title' => 'a') }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Title must be at least 3 characters long'
        )
      end
    end

    context 'when not enough ingredients' do
      let(:recipe_data) { valid_recipe_data.merge('ingredients' => ['spaghetti']) }

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Recipe must have at least 2 ingredients'
        )
      end
    end

    context 'when ingredient is too short' do
      let(:recipe_data) do
        valid_recipe_data.merge('ingredients' => ['spaghetti', 'a'])
      end

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Each ingredient must be at least 2 characters long'
        )
      end
    end

    context 'when not enough instructions' do
      let(:recipe_data) do
        valid_recipe_data.merge('instructions' => ['Boil the spaghetti'])
      end

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Recipe must have at least 2 instructions'
        )
      end
    end

    context 'when instruction is too short' do
      let(:recipe_data) do
        valid_recipe_data.merge('instructions' => [
          'Boil the spaghetti according to package instructions',
          'Cook it'
        ])
      end

      it 'raises ValidationError' do
        expect { subject.perform }.to raise_error(
          Api::V1::RecipeValidator::ValidationError,
          'Each instruction must be at least 10 characters long'
        )
      end
    end
  end
end
