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
      allow(Api::V1::RecipeGenerator).to receive(:perform).and_return(valid_json_response)
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
        json_response = JSON.parse(response.body)
        expect(json_response).to include("recipe", "remaining_requests")
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
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .with("")
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Invalid ingredients input: Input contains invalid characters")

        post :create, params: { ingredients: "" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to generate recipe: Invalid ingredients input: Input contains invalid characters")
      end

      it "returns error for empty array" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .with([])
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Invalid ingredients input: Input contains invalid characters")

        post :create, params: { ingredients: [] }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to generate recipe: Invalid ingredients input: Input contains invalid characters")
      end

      it "returns error for invalid input type" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .with({ name: "tomatoes" })
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Invalid ingredients input: Invalid input type. Expected String or Array, got Hash")

        post :create, params: { ingredients: { name: "tomatoes" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to generate recipe: Invalid ingredients input: Invalid input type. Expected String or Array, got Hash")
      end

      it "returns error for missing ingredients" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .with(nil)
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Invalid ingredients input: Invalid input type. Expected String or Array, got NilClass")

        post :create, params: {}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to generate recipe: Invalid ingredients input: Invalid input type. Expected String or Array, got NilClass")
      end
    end

    context "when recipe generation fails" do
      it "handles RecipeGenerator errors" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(Api::V1::RecipeGenerator::GenerationError, "Generation failed")

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to generate recipe: Generation failed")
      end

      it "handles RecipeParser errors" do
        allow(Api::V1::RecipeParser).to receive(:perform)
          .and_raise(Api::V1::RecipeParser::ParsingError, "Parsing failed")

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to parse recipe: Parsing failed")
      end

      it "handles RecipeCreator errors" do
        allow(Api::V1::RecipeCreator).to receive(:perform)
          .and_raise(Api::V1::RecipeCreator::CreationError, "Creation failed")

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to eq("Failed to create recipe: Creation failed")
      end

      it "handles OpenAI rate limit errors" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("rate limit exceeded"))

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:too_many_requests)
        expect(JSON.parse(response.body)["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_rate_limit"))
      end

      it "handles other OpenAI errors" do
        allow(Api::V1::RecipeGenerator).to receive(:perform)
          .and_raise(OpenAI::Error.new("API error"))

        post :create, params: { ingredients: valid_ingredients }
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq(I18n.t("api.v1.recipes.errors.openai_error", message: "API error"))
      end
    end
  end
end
