require "rails_helper"

RSpec.describe Api::V1::RecipeParser do
  describe ".perform" do
    context "when JSON is valid" do
      let(:valid_json) do
        {
          title: "Simple Tomato Pasta",
          ingredients: ["400g pasta", "4 tomatoes", "3 tbsp olive oil"],
          instructions: ["Boil pasta", "Prepare sauce", "Mix together"]
        }.to_json
      end

      it "returns parsed recipe attributes" do
        result = described_class.perform(valid_json)
        expect(result).to include(
          title: "Simple Tomato Pasta",
          ingredients: ["400g pasta", "4 tomatoes", "3 tbsp olive oil"],
          instructions: ["Boil pasta", "Prepare sauce", "Mix together"]
        )
      end
    end

    context "when JSON is invalid" do
      let(:invalid_json) { "invalid json" }

      it "raises ParsingError" do
        expect {
          described_class.perform(invalid_json)
        }.to raise_error(Api::V1::RecipeParser::ParsingError)
      end
    end
  end
end
