module Api
  module V1
    module ErrorHandler
      extend ActiveSupport::Concern

      included do
        rescue_from StandardError do |e|
          Rails.logger.error "Unexpected error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render_error("An unexpected error occurred", :internal_server_error)
        end

        rescue_from OpenAI::Error do |e|
          if e.message.include?("rate limit")
            render_error("API rate limit exceeded", :too_many_requests)
          else
            render_error("OpenAI API error: #{e.message}", :service_unavailable)
          end
        end

        rescue_from Api::V1::RecipeGenerator::GenerationError do |e|
          render_error("Failed to generate recipe: #{e.message}", :unprocessable_entity)
        end

        rescue_from Api::V1::RecipeParser::ParsingError do |e|
          render_error("Failed to parse recipe: #{e.message}", :unprocessable_entity)
        end

        rescue_from Api::V1::RecipeCreator::CreationError do |e|
          render_error("Failed to create recipe: #{e.message}", :unprocessable_entity)
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
          response[:message] = "Please try again in #{minutes_until_reset} #{'minute'.pluralize(minutes_until_reset)}"
        end

        render json: response, status: status
      end
    end
  end
end
