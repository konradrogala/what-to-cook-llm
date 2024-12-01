require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:ingredients) }
    it { should validate_presence_of(:instructions) }
  end

  describe 'attributes' do
    let(:recipe) { create(:recipe) }

    it 'has a title' do
      expect(recipe.title).to be_a(String)
      expect(recipe.title).not_to be_empty
    end

    it 'has ingredients' do
      expect(recipe.ingredients).to be_an(Array)
      expect(recipe.ingredients).not_to be_empty
      expect(recipe.ingredients).to all(be_a(String))
    end

    it 'has instructions' do
      expect(recipe.instructions).to be_an(Array)
      expect(recipe.instructions).not_to be_empty
      expect(recipe.instructions).to all(be_a(String))
    end
  end

  describe 'database columns' do
    it 'stores ingredients as a string' do
      recipe = create(:recipe)
      expect(recipe.read_attribute(:ingredients)).to be_a(String)
      expect(recipe.read_attribute(:ingredients)).not_to be_empty
    end

    it 'stores instructions as a string' do
      recipe = create(:recipe)
      expect(recipe.read_attribute(:instructions)).to be_a(String)
      expect(recipe.read_attribute(:instructions)).not_to be_empty
    end
  end
end
