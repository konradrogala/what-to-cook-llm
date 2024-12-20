require "rails_helper"

RSpec.describe Api::V1::RecipeCreator do
  let(:valid_attributes) do
    {
      title: "Simple Tomato Pasta",
      ingredients: [ "400g pasta", "4 tomatoes", "3 tbsp olive oil" ],
      instructions: [ "Boil pasta", "Prepare sauce", "Mix together" ]
    }
  end

  describe ".perform" do
    context "when attributes are valid" do
      it "creates a new recipe" do
        expect {
          described_class.perform(valid_attributes)
        }.to change(Recipe, :count).by(1)
      end

      it "returns the created recipe" do
        recipe = described_class.perform(valid_attributes)

        expect(recipe).to be_a(Recipe)
        expect(recipe).to be_persisted
        expect(recipe.title).to eq("Simple Tomato Pasta")
        expect(recipe.ingredients_array).to eq([ "400g pasta", "4 tomatoes", "3 tbsp olive oil" ])
        expect(recipe.instructions_array).to eq([ "Boil pasta", "Prepare sauce", "Mix together" ])
      end

      it "serializes recipe correctly" do
        recipe = described_class.perform(valid_attributes)
        json = recipe.as_json

        expect(json["title"]).to eq("Simple Tomato Pasta")
        expect(json["ingredients"]).to eq([ "400g pasta", "4 tomatoes", "3 tbsp olive oil" ])
        expect(json["instructions"]).to eq([ "Boil pasta", "Prepare sauce", "Mix together" ])
      end
    end

    context "when attributes are invalid" do
      let(:invalid_attributes) { {} }

      it "raises CreationError" do
        expect {
          described_class.perform(invalid_attributes)
        }.to raise_error(Api::V1::RecipeCreator::CreationError, "Invalid recipe attributes")
      end

      it "does not create a recipe" do
        expect {
          described_class.perform(invalid_attributes)
        }.to raise_error(Api::V1::RecipeCreator::CreationError)
        expect(Recipe.count).to eq(0)
      end
    end
  end
end
