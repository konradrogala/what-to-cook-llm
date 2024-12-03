require "rails_helper"

RSpec.describe Api::V1::RecipesController, type: :controller do
  describe "POST #create" do
    let(:valid_ingredients) { "tomatoes, pasta" }
    let(:valid_json_response) do
      {
        title: "Pasta",
        ingredients: [ "tomatoes", "pasta" ],
        instructions: [ "Cook pasta" ]
      }.to_json
    end
    let(:valid_recipe_attributes) do
      {
        title: "Pasta",
        ingredients: [ "tomatoes", "pasta" ],
        instructions: [ "Cook pasta" ]
      }
    end
    let(:valid_recipe) do
      create(:recipe,
        title: "Pasta",
        ingredients: "tomatoes\npasta",
        instructions: "Cook pasta"
      )
    end

    before do
      allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform).and_return(valid_ingredients)
      allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform).and_return(valid_json_response)
      allow(Api::V1::RecipeParser).to receive(:perform).and_return(valid_recipe_attributes)
      allow(Api::V1::RecipeCreator).to receive(:perform).and_return(valid_recipe)
      session[:api_requests_count] = 0
    end

    context "with valid parameters" do
      it "creates a new recipe" do
        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:created)
      end

      it "returns recipe and remaining requests" do
        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:created)
        expect(json_response["recipe"]).to include(
          "title" => "Pasta",
          "ingredients" => [ "tomatoes", "pasta" ],
          "instructions" => [ "Cook pasta" ]
        )
      end

      it "accepts array of ingredients" do
        post :create, params: { ingredients: [ "tomatoes", "pasta" ] }
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "returns error for empty ingredients" do
        allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform)
          .and_raise(Api::V1::IngredientsProcessor::ProcessingError.new("Ingredients cannot be empty"))

        post :create, params: { ingredients: "" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Ingredients cannot be empty"))
      end

      it "returns error for empty array" do
        allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform)
          .and_raise(Api::V1::IngredientsProcessor::ProcessingError.new("Ingredients cannot be empty"))

        post :create, params: { ingredients: [] }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Ingredients cannot be empty"))
      end

      it "returns error for invalid input type" do
        allow_any_instance_of(Api::V1::IngredientsProcessor).to receive(:perform)
          .and_raise(Api::V1::IngredientsProcessor::ProcessingError.new("Invalid ingredients format. Expected String or Array"))

        post :create, params: { ingredients: { name: "tomatoes" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Invalid ingredients format. Expected String or Array"))
      end

      it "returns error for missing ingredients" do
        post :create, params: {}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Ingredients cannot be empty"))
      end
    end

    context "when recipe generation fails" do
      it "handles RecipeGenerator errors" do
        allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Generation failed")

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Generation failed"))
      end

      it "handles OpenAI rate limit errors" do
        allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("rate limit exceeded"))

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:too_many_requests)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_rate_limit"))
      end

      it "handles other OpenAI errors" do
        allow_any_instance_of(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("other error"))

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:service_unavailable)
        expect(json_response["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_error", message: "other error"))
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
