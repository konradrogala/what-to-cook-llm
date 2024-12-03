require "rails_helper"

RSpec.describe Api::V1::IngredientsProcessor do
  describe "#perform" do
    subject(:process_ingredients) { described_class.perform(ingredients) }

    context "when ingredients is a string" do
      let(:ingredients) { "tomatoes, onion,garlic, olive oil" }

      it "splits by comma and strips whitespace" do
        expect(process_ingredients).to eq(["tomatoes", "onion", "garlic", "olive oil"])
      end
    end

    context "when ingredients is an array" do
      let(:ingredients) { ["tomatoes", "onion", "garlic", "olive oil"] }

      it "keeps array format and strips whitespace" do
        expect(process_ingredients).to eq(["tomatoes", "onion", "garlic", "olive oil"])
      end
    end

    context "when ingredients contain HTML tags" do
      let(:ingredients) { ["<b>tomatoes</b>", "<i>onion</i>", "<script>alert('garlic')</script>"] }

      it "sanitizes HTML tags" do
        expect(process_ingredients).to eq(["tomatoes", "onion", "alert('garlic')"])
      end
    end

    context "when ingredients is neither string nor array" do
      let(:ingredients) { { tomatoes: 1, onion: 2 } }

      it "raises ProcessingError" do
        expect { process_ingredients }.to raise_error(
          Api::V1::IngredientsProcessor::ProcessingError,
          "Invalid ingredients format. Expected String or Array"
        )
      end
    end

    context "when array contains non-string elements" do
      let(:ingredients) { [1, :onion, "garlic"] }

      it "converts all elements to strings" do
        expect(process_ingredients).to eq(["1", "onion", "garlic"])
      end
    end

    context "when string has irregular spacing" do
      let(:ingredients) { "  tomatoes,   onion  ,garlic   " }

      it "normalizes whitespace" do
        expect(process_ingredients).to eq(["tomatoes", "onion", "garlic"])
      end
    end
  end
end
