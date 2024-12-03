module Api
  module V1
    module ErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from StandardError do |e|
          Rails.logger.error "Unexpected error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render_error(I18n.t("api.v1.recipes.errors.unexpected"), :internal_server_error)
        end

        rescue_from OpenAI::Error do |e|
          if e.message.include?("rate limit")
            render_error(I18n.t("api.v1.recipes.errors.openai_rate_limit"), :too_many_requests)
          else
            render_error(I18n.t("api.v1.recipes.errors.openai_error", message: e.message), :service_unavailable)
          end
        end

        rescue_from Api::V1::RecipeGenerator::GenerationError do |e|
          render_error(I18n.t("api.v1.recipes.errors.recipe_generation", message: e.message), :unprocessable_entity)
        end

        rescue_from Api::V1::RecipeParser::ParsingError do |e|
          render_error(I18n.t("api.v1.recipes.errors.recipe_parsing", message: e.message), :unprocessable_entity)
        end

        rescue_from Api::V1::RecipeCreator::CreationError do |e|
          render_error(I18n.t("api.v1.recipes.errors.recipe_creation", message: e.message), :unprocessable_entity)
        end

        rescue_from Api::V1::IngredientsProcessor::ProcessingError do |e|
          render_error(I18n.t("api.v1.recipes.errors.recipe_generation", message: e.message), :unprocessable_entity)
        end

        rescue_from ActionController::ParameterMissing do |e|
          render_error(I18n.t("api.v1.recipes.errors.recipe_generation", message: "Ingredients cannot be empty"), :unprocessable_entity)
        end
      end

      private

      def render_error(message, status)
        counter = Api::V1::RequestCounter.new(session)
        response = {
          error: message,
          remaining_requests: counter.remaining_requests
        }

        # Add reset time information for rate limit errors
        if status == :too_many_requests && session[:api_requests_reset_time]
          minutes_until_reset = ((session[:api_requests_reset_time] - Time.now.to_i) / 60.0).ceil
          response[:reset_in_minutes] = minutes_until_reset
          response[:message] = I18n.t("api.v1.recipes.messages.reset_time", minutes: minutes_until_reset)
        end

        render json: response, status: status
      end
    end
  end
end
