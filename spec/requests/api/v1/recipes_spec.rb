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

      it "properly decrements remaining requests after successful request" do
        # First request
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(4)

        # Second request
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(3)
      end

      it "does not decrement remaining requests for failed requests" do
        # Failed request
        post "/api/v1/recipes", params: { ingredients: [] }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)

        # Successful request after failure
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(4)
      end

      it "blocks requests when limit is reached" do
        # Exhaust the limit
        5.times do
          post "/api/v1/recipes", params: valid_params, as: :json
          expect(response).to have_http_status(:created)
        end

        # Try one more request
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(429)
        expect(json_response["error"]).to include("Rate limit exceeded")
      end
    end

    context "when the request is successful" do
      before { setup_api_session }

      it "returns the created recipe and remaining requests" do
        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response["recipe"]).to include(
          "title" => "Test Recipe",
          "ingredients" => [ "tomato", "pasta" ],
          "instructions" => [ "Step 1", "Step 2" ]
        )
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end

    context "when ingredients are empty" do
      before { setup_api_session }

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: [] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Ingredients cannot be empty")
      end
    end

    context "when ingredients are missing" do
      before { setup_api_session }

      it "returns an error" do
        post "/api/v1/recipes", params: {}, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Ingredients cannot be empty")
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
