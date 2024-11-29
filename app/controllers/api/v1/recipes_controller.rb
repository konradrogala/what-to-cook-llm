class Api::V1::RecipesController < ApplicationController
  def create
    ingredients = params[:ingredients]

    if ingredients.blank? || ingredients.empty?
      render json: { error: "Ingredients cannot be empty" }, status: :unprocessable_entity
      return
    end

    begin
      # Initialize OpenAI client
      client = OpenAI::Client.new
      Rails.logger.info "OpenAI client initialized"

      # Generate recipe using GPT-4
      prompt = "Generate a recipe using these ingredients: #{ingredients}. Format the response as JSON with the following structure: { title: string, ingredients: array of strings, instructions: array of strings }"

      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo-1106",  # Changed to a more widely available model with JSON support
          messages: [{ role: "user", content: prompt }],
          response_format: { type: "json_object" }
        }
      )
      Rails.logger.info "Successfully received response from OpenAI API"
      Rails.logger.debug "Response: #{response.inspect}"

      recipe_data = JSON.parse(response.dig("choices", 0, "message", "content"))
      Rails.logger.info "Successfully parsed recipe data"
      Rails.logger.debug "Recipe data: #{recipe_data.inspect}"

      @recipe = Recipe.new(
        title: recipe_data["title"],
        ingredients: recipe_data["ingredients"].join("\n"),
        instructions: recipe_data["instructions"].join("\n")
      )

      if @recipe.save
        Rails.logger.info "Recipe saved successfully"
        render json: @recipe, status: :created
      else
        Rails.logger.error "Failed to save recipe: #{@recipe.errors.full_messages.join(', ')}"
        render json: { title: @recipe.errors.full_messages }, status: :unprocessable_entity
      end

    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse recipe data: #{e.message}"
      render json: { error: "Invalid response format from AI" }, status: :unprocessable_entity
    rescue OpenAI::Error => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      render json: { error: "Failed to generate recipe" }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      render json: { error: "An unexpected error occurred" }, status: :internal_server_error
    end
  end
end
