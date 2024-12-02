# frozen_string_literal: true

module Api
  module V1
    class RequestCounter
      def initialize(session)
        @session = session
        ensure_initialized
      end

      def increment
        session[:api_requests_count] = current_count + 1
      end

      def current_count
        session[:api_requests_count].to_i
      end

      def remaining_requests
        max_remaining = ApiRequestLimiter::MAX_REQUESTS - current_count
        [ max_remaining, 0 ].max
      end

      def limit_exceeded?
        current_count >= ApiRequestLimiter::MAX_REQUESTS
      end

      def reset_if_expired
        if reset_time_expired?
          session[:api_requests_count] = 0
          session[ApiRequestLimiter::RESET_TIME_KEY] = 1.hour.from_now.to_i
        end
      end

      private

      attr_reader :session

      def reset_time_expired?
        session[ApiRequestLimiter::RESET_TIME_KEY].nil? ||
          Time.now.to_i >= session[ApiRequestLimiter::RESET_TIME_KEY]
      end

      def ensure_initialized
        if session[:api_requests_count].nil?
          session[:api_requests_count] = 0
          session[ApiRequestLimiter::RESET_TIME_KEY] = 1.hour.from_now.to_i
        end
      end
    end
  end
end
