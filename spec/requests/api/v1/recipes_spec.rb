require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "POST /api/v1/recipes" do
    let(:valid_params) do
      {
        ingredients: [ "tomato", "pasta" ]
      }
    end
    let(:valid_json_response) do
      {
        title: "Test Recipe",
        ingredients: [ "tomato", "pasta" ],
        instructions: [ "Step 1", "Step 2" ]
      }.to_json
    end
    let(:valid_recipe_attributes) do
      {
        title: "Test Recipe",
        ingredients: [ "tomato", "pasta" ],
        instructions: [ "Step 1", "Step 2" ]
      }
    end
    let(:valid_recipe) do
      create(:recipe,
        title: "Test Recipe",
        ingredients: "tomato\npasta",
        instructions: "Step 1\nStep 2"
      )
    end

    before do
      allow(Api::V1::RecipeGenerator).to receive(:perform).and_return(valid_json_response)
      allow(Api::V1::RecipeParser).to receive(:perform).and_return(valid_recipe_attributes)
      allow(Api::V1::RecipeCreator).to receive(:perform).and_return(valid_recipe)
    end

    context "when tracking request counts" do
      before { setup_api_session }

      it "decrements remaining requests after each request" do
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(4)

        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(3)
      end

      it "blocks requests after reaching the limit" do
        # Make 5 requests to reach the limit (starting from 1)
        5.times do
          post "/api/v1/recipes", params: valid_params, as: :json
        end

        # This should be blocked
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:too_many_requests)
        expect(json_response["error"]).to include("Rate limit exceeded")
        expect(json_response["remaining_requests"]).to eq(0)
      end
    end

    context "when request is successful" do
      before { setup_api_session }

      it "returns the recipe with remaining requests" do
        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response["recipe"]["title"]).to eq("Test Recipe")
        expect(json_response["recipe"]["ingredients"]).to eq(["tomato", "pasta"])
        expect(json_response["recipe"]["instructions"]).to eq(["Step 1", "Step 2"])
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end

    context "when ingredients are missing" do
      before { setup_api_session }

      it "returns an error" do
        post "/api/v1/recipes", params: {}, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Failed to generate recipe: Ingredients cannot be empty")
        expect(json_response["remaining_requests"]).to eq(5)
      end
    end

    context "when ingredients have invalid format" do
      before { setup_api_session }

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: { invalid: "format" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Failed to generate recipe: Invalid ingredients format. Expected String or Array")
        expect(json_response["remaining_requests"]).to eq(5)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
