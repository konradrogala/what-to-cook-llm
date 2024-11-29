require 'rails_helper'

RSpec.describe Api::V1::RecipeCreator do
  let(:valid_attributes) do
    {
      title: "Simple Tomato Pasta",
      ingredients: "400g pasta\n4 tomatoes\n3 tbsp olive oil",
      instructions: "Boil pasta\nPrepare sauce\nMix together"
    }
  end

  describe '.call' do
    context 'when attributes are valid' do
      it 'creates a new recipe' do
        expect {
          described_class.call(valid_attributes)
        }.to change(Recipe, :count).by(1)
      end

      it 'returns the created recipe' do
        recipe = described_class.call(valid_attributes)
        expect(recipe).to be_a(Recipe)
        expect(recipe.title).to eq("Simple Tomato Pasta")
      end
    end

    context 'when attributes are invalid' do
      let(:invalid_attributes) { { title: nil } }

      it 'raises CreationError' do
        expect {
          described_class.call(invalid_attributes)
        }.to raise_error(Api::V1::RecipeCreator::CreationError)
      end
    end
  end
end
