require "rails_helper"

RSpec.describe Api::V1::RecipeGenerator do
  let(:ingredients) { "tomatoes, pasta, olive oil" }
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:api_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => {
              "title" => "Simple Tomato Pasta",
              "ingredients" => [ "400g pasta", "4 tomatoes", "3 tbsp olive oil" ],
              "instructions" => [ "Boil pasta", "Prepare sauce", "Mix together" ]
            }.to_json
          }
        }
      ]
    }
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)
  end

  describe ".perform" do
    context "when input is valid" do
      before do
        allow(openai_client).to receive(:chat).and_return(api_response)
      end

      it "returns JSON content from API response" do
        result = described_class.perform(ingredients)
        expect(JSON.parse(result)).to include(
          "title" => "Simple Tomato Pasta"
        )
      end

      it "handles array input" do
        result = described_class.perform([ "tomatoes", "pasta", "olive oil" ])
        expect(JSON.parse(result)).to include(
          "title" => "Simple Tomato Pasta"
        )
      end

      it "sanitizes input before sending to API" do
        expect(described_class.perform(" tomatoes & pasta ")).to be_a(String)
      end
    end

    context "when input is invalid" do
      it "raises error for SQL injection attempt" do
        expect {
          described_class.perform("tomatoes; DROP TABLE recipes;")
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, /Invalid ingredients input/)
      end

      it "raises error for too long input" do
        long_input = "a" * (InputSanitizer::MAX_INPUT_LENGTH + 1)
        expect {
          described_class.perform(long_input)
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, /Invalid ingredients input/)
      end

      it "raises error for invalid input type" do
        expect {
          described_class.perform({ ingredient: "tomatoes" })
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, /Invalid ingredients input/)
      end
    end

    context "when API call fails" do
      before do
        allow(openai_client).to receive(:chat).and_raise(OpenAI::Error.new("API Error"))
      end

      it "raises GenerationError" do
        expect {
          described_class.perform(ingredients)
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, /Failed to generate recipe/)
      end
    end
  end
end
