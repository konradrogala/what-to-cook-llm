FactoryBot.define do
  factory :recipe do
    title { "Simple Tomato Pasta" }
    ingredients { "400g pasta\n4 tomatoes\n3 tbsp olive oil" }
    instructions { "Boil pasta\nPrepare sauce\nMix together" }
  end
end
