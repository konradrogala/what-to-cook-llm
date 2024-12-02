require 'rails_helper'

RSpec.describe Api::V1::RecipeFeasibilityChecker do
  let(:valid_recipe) do
    {
      'title' => 'Spaghetti Bolognese',
      'ingredients' => [
        'spaghetti',
        'ground beef',
        'tomato sauce',
        'onion',
        'garlic',
        'olive oil',
        'salt',
        'pepper'
      ],
      'instructions' => [
        'Boil water and cook spaghetti according to package instructions (about 8-10 minutes)',
        'Heat olive oil in a pan over medium heat and sauté chopped onion and garlic until soft',
        'Add ground beef and cook until browned, about 5-7 minutes',
        'Add tomato sauce and seasonings, simmer for 15-20 minutes',
        'Serve sauce over cooked pasta'
      ]
    }
  end

  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:feasible_response) do
    {
      'choices' => [ {
        'message' => {
          'content' => {
            is_feasible: true,
            issues: [],
            suggestions: [ 'Consider adding grated parmesan cheese as a garnish' ]
          }.to_json
        }
      } ]
    }
  end

  let(:not_feasible_response) do
    {
      'choices' => [ {
        'message' => {
          'content' => {
            is_feasible: false,
            issues: [ 'Missing cooking temperature for the sauce' ],
            suggestions: [ 'Add specific temperature for simmering the sauce' ]
          }.to_json
        }
      } ]
    }
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
  end

  describe '#perform' do
    context 'when recipe is feasible' do
      before do
        allow(openai_client).to receive(:chat).and_return(feasible_response)
      end

      it 'returns suggestions for improvement' do
        result = described_class.perform(valid_recipe)
        expect(result).to include('Consider adding grated parmesan cheese as a garnish')
      end
    end

    context 'when recipe is not feasible' do
      before do
        allow(openai_client).to receive(:chat).and_return(not_feasible_response)
      end

      it 'raises FeasibilityError with issues' do
        expect {
          described_class.perform(valid_recipe)
        }.to raise_error(
          Api::V1::RecipeFeasibilityChecker::FeasibilityError,
          'Recipe may not be feasible: Missing cooking temperature for the sauce'
        )
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(openai_client).to receive(:chat)
          .and_raise(OpenAI::Error.new("API error"))
      end

      it 'raises FeasibilityError' do
        expect {
          described_class.perform(valid_recipe)
        }.to raise_error(
          Api::V1::RecipeFeasibilityChecker::FeasibilityError,
          'Failed to check recipe feasibility: API error'
        )
      end
    end

    context 'when response is invalid JSON' do
      before do
        allow(openai_client).to receive(:chat).and_return({
          'choices' => [ {
            'message' => {
              'content' => 'invalid json'
            }
          } ]
        })
      end

      it 'raises FeasibilityError' do
        expect {
          described_class.perform(valid_recipe)
        }.to raise_error(
          Api::V1::RecipeFeasibilityChecker::FeasibilityError,
          'Invalid response format from feasibility check'
        )
      end
    end
  end
end
