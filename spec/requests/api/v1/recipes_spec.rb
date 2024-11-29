require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "POST /api/v1/recipes" do
    let(:valid_ingredients) { "tomatoes, pasta, olive oil" }
    let(:api_response) do
      {
        "choices" => [{
          "message" => {
            "content" => {
              "title" => "Simple Tomato Pasta",
              "ingredients" => ["400g pasta", "4 tomatoes", "3 tbsp olive oil"],
              "instructions" => ["Boil pasta", "Prepare sauce", "Mix together"]
            }.to_json
          }
        }]
      }
    end

    let(:openai_client) { instance_double(OpenAI::Client) }

    before do
      allow(OpenAI::Client).to receive(:new).and_return(openai_client)
      allow(openai_client).to receive(:chat).with(
        parameters: {
          model: "gpt-3.5-turbo-1106",
          messages: [{ role: "user", content: /Generate a recipe using these ingredients:.*/ }],
          response_format: { type: "json_object" }
        }
      ).and_return(api_response)
    end

    context "when the request is successful" do
      it "creates a new recipe" do
        expect {
          post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        }.to change(Recipe, :count).by(1)
      end

      it "returns the created recipe" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["title"]).to eq("Simple Tomato Pasta")
      end
    end

    context "when the OpenAI API fails" do
      before do
        allow(openai_client).to receive(:chat).and_raise(OpenAI::Error.new("API Error"))
      end

      it "returns an error response" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:service_unavailable)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to generate recipe")
      end
    end

    context "when the API response is not valid JSON" do
      let(:invalid_api_response) do
        {
          "choices" => [{
            "message" => {
              "content" => "Invalid JSON"
            }
          }]
        }
      end

      before do
        allow(openai_client).to receive(:chat).and_return(invalid_api_response)
      end

      it "returns an error response" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid response format from AI")
      end
    end

    context "when the recipe fails to save" do
      before do
        allow_any_instance_of(Recipe).to receive(:save).and_return(false)
        allow_any_instance_of(Recipe).to receive(:errors).and_return(
          double(full_messages: ["Title can't be blank"])
        )
      end

      it "returns an error response" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key("title")
      end
    end

    context "when no ingredients are provided" do
      it "returns an error response" do
        post "/api/v1/recipes", params: { ingredients: nil }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Ingredients cannot be empty")
      end
    end
  end
end
