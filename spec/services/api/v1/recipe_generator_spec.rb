require "rails_helper"

RSpec.describe Api::V1::RecipeGenerator do
  let(:ingredients) { "tomatoes, pasta, olive oil" }
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:feasibility_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => "yes"
          }
        }
      ]
    }
  end
  let(:recipe_response) do
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
        # Mock both the feasibility check and recipe generation calls
        allow(openai_client).to receive(:chat).with(
          parameters: hash_including(
            messages: array_including(
              hash_including(content: include("analyze if they can make a coherent dish"))
            )
          )
        ).and_return(feasibility_response)

        allow(openai_client).to receive(:chat).with(
          parameters: hash_including(
            messages: array_including(
              hash_including(content: include("Create a recipe"))
            )
          )
        ).and_return(recipe_response)
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
      let(:feasibility_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "no"
              }
            }
          ]
        }
      end

      before do
        allow(openai_client).to receive(:chat).and_return(feasibility_response)
      end

      it "raises error for empty input" do
        expect {
          described_class.perform("")
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError)
      end

      it "raises error for nil input" do
        expect {
          described_class.perform(nil)
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError)
      end

      it "raises error for invalid ingredients combination" do
        expect {
          described_class.perform("coffee, sushi, chocolate")
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, "These ingredients cannot make a coherent dish")
      end
    end

    context "when API call fails" do
      before do
        allow(openai_client).to receive(:chat).and_raise(OpenAI::Error.new("API error"))
      end

      it "wraps and re-raises the error" do
        expect {
          described_class.perform(ingredients)
        }.to raise_error(Api::V1::RecipeGenerator::GenerationError, "Failed to generate recipe: API error")
      end
    end
  end
end
