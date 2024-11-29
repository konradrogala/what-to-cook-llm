require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "POST /api/v1/recipes" do
    let(:valid_params) do
      {
        ingredients: ["tomato", "pasta"]
      }
    end

    before do
      allow(Api::V1::RecipeGenerator).to receive(:perform).and_return(
        {
          title: "Test Recipe",
          ingredients: ["tomato", "pasta"],
          instructions: ["Step 1", "Step 2"]
        }.to_json
      )
    end

    context "when the request is successful" do
      it "returns the created recipe and remaining requests" do
        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response["recipe"]).to include(
          "title" => "Test Recipe",
          "ingredients" => ["tomato", "pasta"],
          "instructions" => ["Step 1", "Step 2"]
        )
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end

    context "when ingredients are empty" do
      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: [] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Ingredients cannot be empty")
      end
    end

    context "when ingredients are missing" do
      it "returns an error" do
        post "/api/v1/recipes", params: {}, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Ingredients cannot be empty")
      end
    end
  end
end
