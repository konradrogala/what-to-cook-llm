# frozen_string_literal: true

module ApiHelpers
  def setup_api_session
    @session = {}
    allow_any_instance_of(ActionDispatch::Request)
      .to receive(:session)
      .and_return(@session)

    @session[ApiRequestLimiter::RESET_TIME_KEY] = 1.hour.from_now.to_i
  end

  def json_response
    JSON.parse(response.body)
  end

  def valid_recipe_json
    {
      title: "Delicious Recipe",
      ingredients: ["ingredient1", "ingredient2"],
      instructions: ["step1", "step2"],
      cooking_time: "30 minutes",
      servings: 4,
      difficulty: "medium"
    }.to_json
  end

  def valid_recipe_attributes
    {
      title: "Delicious Recipe",
      ingredients: ["ingredient1", "ingredient2"],
      instructions: ["step1", "step2"],
      cooking_time: "30 minutes",
      servings: 4,
      difficulty: "medium"
    }
  end

  def recipe
    Recipe.new(valid_recipe_attributes)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
