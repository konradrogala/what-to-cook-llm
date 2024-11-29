require_relative '../../app/middleware/api_request_limiter'

Rails.application.config.middleware.use ActionDispatch::Session::CookieStore
Rails.application.config.middleware.use ApiRequestLimiter
