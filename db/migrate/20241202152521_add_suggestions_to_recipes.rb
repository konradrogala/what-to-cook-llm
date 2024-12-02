class AddSuggestionsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :suggestions, :text
  end
end
