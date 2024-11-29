require 'rails_helper'

RSpec.describe Api::V1::RecipeParser do
  let(:valid_json) do
    {
      "title" => "Simple Tomato Pasta",
      "ingredients" => ["400g pasta", "4 tomatoes", "3 tbsp olive oil"],
      "instructions" => ["Boil pasta", "Prepare sauce", "Mix together"]
    }.to_json
  end

  describe '.perform' do
    context 'when JSON is valid' do
      it 'returns parsed recipe attributes' do
        result = described_class.perform(valid_json)
        expect(result).to include(
          title: "Simple Tomato Pasta",
          ingredients: "400g pasta\n4 tomatoes\n3 tbsp olive oil",
          instructions: "Boil pasta\nPrepare sauce\nMix together"
        )
      end
    end

    context 'when JSON is invalid' do
      let(:invalid_json) { '{invalid_json' }

      it 'raises ParsingError' do
        expect {
          described_class.perform(invalid_json)
        }.to raise_error(Api::V1::RecipeParser::ParsingError, /Invalid recipe format/)
      end
    end
  end
end
