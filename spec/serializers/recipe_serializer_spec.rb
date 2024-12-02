# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecipeSerializer do
  let(:recipe) do
    Recipe.new(
      title: "Test Recipe",
      ingredients: "ingredient1\ningredient2",
      instructions: "step1\nstep2"
    )
  end

  subject(:serialized_recipe) { described_class.new(recipe).as_json }

  it "serializes the recipe title" do
    expect(serialized_recipe[:title]).to eq("Test Recipe")
  end

  it "serializes the recipe ingredients" do
    expect(serialized_recipe[:ingredients]).to eq(["ingredient1", "ingredient2"])
  end

  it "serializes the recipe instructions" do
    expect(serialized_recipe[:instructions]).to eq(["step1", "step2"])
  end

  it "includes created_at timestamp" do
    expect(serialized_recipe[:created_at]).to eq(recipe.created_at)
  end

  it "includes updated_at timestamp" do
    expect(serialized_recipe[:updated_at]).to eq(recipe.updated_at)
  end
end
