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
    let(:request_counter) { instance_double(Api::V1::RequestCounter) }

    before do
      allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform).and_return(valid_params[:ingredients])
      allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform).and_return(valid_json_response)
      allow(Api::V1::RecipeParser).to receive(:perform).and_return(valid_recipe_attributes)
      allow(Api::V1::RecipeCreator).to receive(:perform).and_return(valid_recipe)
      allow(Api::V1::RequestCounter).to receive(:new).and_return(request_counter)
      allow(request_counter).to receive(:reset_if_expired)
      allow(request_counter).to receive(:current_count).and_return(0)
    end

    context "when tracking request counts" do
      before do
        setup_api_session
        @remaining_requests = 5
        @current_count = 0
        allow(request_counter).to receive(:limit_exceeded?).and_return(false)
        allow(request_counter).to receive(:increment) do
          @current_count += 1
          @remaining_requests -= 1
        end
        allow(request_counter).to receive(:remaining_requests) { @remaining_requests }
        allow(request_counter).to receive(:current_count) { @current_count }
      end

      it "decrements remaining requests after each request" do
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(4)

        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["remaining_requests"]).to eq(3)
      end

      it "blocks requests after reaching the limit" do
        # Make 5 requests to reach the limit
        4.times do
          post "/api/v1/recipes", params: valid_params, as: :json
        end

        # Last allowed request
        allow(request_counter).to receive(:limit_exceeded?).and_return(false, true)
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(json_response["limit_reached"]).to be true

        # This should be blocked
        allow(request_counter).to receive(:limit_exceeded?).and_return(true)
        post "/api/v1/recipes", params: valid_params, as: :json
        expect(response).to have_http_status(:too_many_requests)
        expect(json_response["error"]).to include("Rate limit exceeded")
        expect(json_response["remaining_requests"]).to eq(0)
      end
    end

    context "when request is successful" do
      before do
        setup_api_session
        allow(request_counter).to receive(:limit_exceeded?).and_return(false)
        allow(request_counter).to receive(:increment)
        allow(request_counter).to receive(:remaining_requests).and_return(4)
      end

      it "returns the recipe with remaining requests" do
        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response["recipe"]["title"]).to eq("Test Recipe")
        expect(json_response["recipe"]["ingredients"]).to eq([ "tomato", "pasta" ])
        expect(json_response["recipe"]["instructions"]).to eq([ "Step 1", "Step 2" ])
        expect(json_response["remaining_requests"]).to eq(4)
      end
    end

    context "when ingredients are missing" do
      before do
        setup_api_session
        allow(request_counter).to receive(:limit_exceeded?).and_return(false)
        allow(request_counter).to receive(:remaining_requests).and_return(5)
      end

      it "returns an error" do
        post "/api/v1/recipes", params: {}, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Ingredients cannot be empty"))
        expect(json_response["remaining_requests"]).to eq(5)
      end
    end

    context "when ingredients have invalid format" do
      before do
        setup_api_session
        allow(request_counter).to receive(:limit_exceeded?).and_return(false)
        allow(request_counter).to receive(:remaining_requests).and_return(5)
        allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform)
          .and_raise(Api::V1::IngredientsProcessor::ProcessingError.new("Invalid ingredients format. Expected String or Array"))
      end

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: { invalid: "format" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Invalid ingredients format. Expected String or Array"))
        expect(json_response["remaining_requests"]).to eq(5)
      end
    end

    context "when OpenAI API fails" do
      before do
        setup_api_session
        allow(request_counter).to receive(:limit_exceeded?).and_return(false)
        allow(request_counter).to receive(:remaining_requests).and_return(5)
      end

      it "handles rate limit errors" do
        allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("rate limit exceeded"))

        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:too_many_requests)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_rate_limit"))
        expect(json_response["remaining_requests"]).to eq(5)
      end

      it "handles other API errors" do
        allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("other error"))

        post "/api/v1/recipes", params: valid_params, as: :json

        expect(response).to have_http_status(:service_unavailable)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_error", message: "other error"))
        expect(json_response["remaining_requests"]).to eq(5)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end

  def setup_api_session
    allow(request_counter).to receive(:reset_if_expired)
  end
end
