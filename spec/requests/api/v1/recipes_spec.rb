require 'rails_helper'

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "POST /api/v1/recipes" do
    let(:valid_ingredients) { "tomatoes, pasta, olive oil" }
    let(:json_content) do
      {
        "title" => "Simple Tomato Pasta",
        "ingredients" => ["400g pasta", "4 tomatoes", "3 tbsp olive oil"],
        "instructions" => ["Boil pasta", "Prepare sauce", "Mix together"]
      }.to_json
    end

    let(:recipe_attributes) do
      {
        title: "Simple Tomato Pasta",
        ingredients: "400g pasta\n4 tomatoes\n3 tbsp olive oil",
        instructions: "Boil pasta\nPrepare sauce\nMix together"
      }
    end

    before do
      allow(Api::V1::RecipeGenerator).to receive(:call).with(valid_ingredients).and_return(json_content)
      allow(Api::V1::RecipeParser).to receive(:call).with(json_content).and_return(recipe_attributes)
      allow(Api::V1::RecipeCreator).to receive(:call).with(recipe_attributes).and_return(
        Recipe.new(recipe_attributes.merge(id: 1))
      )
    end

    context "when the request is successful" do
      it "returns the created recipe" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["title"]).to eq("Simple Tomato Pasta")
      end
    end

    context "when ingredients are empty" do
      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: "" }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "Ingredients cannot be empty")
      end
    end

    context "when recipe generation fails" do
      before do
        allow(Api::V1::RecipeGenerator).to receive(:call).and_raise(
          Api::V1::RecipeGenerator::GenerationError.new("API Error")
        )
      end

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include("error" => "API Error")
      end
    end

    context "when recipe parsing fails" do
      before do
        allow(Api::V1::RecipeParser).to receive(:call).and_raise(
          Api::V1::RecipeParser::ParsingError.new("Invalid format")
        )
      end

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "Invalid format")
      end
    end

    context "when recipe creation fails" do
      before do
        allow(Api::V1::RecipeCreator).to receive(:call).and_raise(
          Api::V1::RecipeCreator::CreationError.new("Invalid title")
        )
      end

      it "returns an error" do
        post "/api/v1/recipes", params: { ingredients: valid_ingredients }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "Invalid title")
      end
    end
  end
end
