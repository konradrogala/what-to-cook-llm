class ApiRequestLimiter
  MAX_REQUESTS = 5
  RESET_TIME_KEY = "api_requests_reset_time"

  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip middleware for non-API requests
    return @app.call(env) unless api_request?(env)

    request = Rack::Request.new(env)
    counter = Api::V1::RequestCounter.new(request.session)

    Rails.logger.info "[MIDDLEWARE] Request path: #{request.path}"
    Rails.logger.info "[MIDDLEWARE] Request method: #{request.request_method}"
    Rails.logger.info "[MIDDLEWARE] Accept header: #{env['HTTP_ACCEPT']}"
    Rails.logger.info "[MIDDLEWARE] Initial count: #{counter.current_count}"

    counter.reset_if_expired

    # Call the app
    status, headers, response = @app.call(env)

    # Check if the count has been incremented and now exceeds the limit
    if counter.limit_exceeded?
      Rails.logger.warn "[MIDDLEWARE] Rate limit exceeded after request"
      ensure_reset_time(request.session)

      # If the response was successful, modify it to include rate limit info
      if status == 201 || status == 200
        begin
          # Convert response body to string and parse JSON
          response_body = response.respond_to?(:body) ? response.body : response[0]
          response_body = response_body.respond_to?(:first) ? response_body.first : response_body
          body = JSON.parse(response_body)

          body["limit_reached"] = true
          body["message"] = "You have reached the maximum number of requests for this session."
          body["remaining_requests"] = 0

          # Create new response with modified body
          response = [ body.to_json ]
        rescue JSON::ParserError => e
          Rails.logger.error "[MIDDLEWARE] Failed to parse response body: #{e.message}"
        end
      end
    end

    Rails.logger.info "[MIDDLEWARE] Response status: #{status}"
    Rails.logger.info "[MIDDLEWARE] Final count: #{counter.current_count}"

    [ status, headers, response ]
  end

  private

  def api_request?(env)
    path = env["REQUEST_PATH"] || env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    accept = env["HTTP_ACCEPT"]

    Rails.logger.info "[MIDDLEWARE] Checking request: path=#{path}, method=#{method}, accept=#{accept}"

    path&.start_with?("/api/v1/recipes") &&
      method == "POST" &&
      accept&.include?("application/json")
  end

  def ensure_reset_time(session)
    return if session[RESET_TIME_KEY]
    session[RESET_TIME_KEY] = 1.hour.from_now.to_i
  end

  def rate_limit_response(reset_time)
    minutes_until_reset = ((reset_time - Time.now.to_i) / 60.0).ceil
    [
      429,
      { "Content-Type" => "application/json" },
      [ {
        error: "Rate limit exceeded. Maximum #{MAX_REQUESTS} requests per hour allowed.",
        remaining_requests: 0,
        minutes_until_reset: minutes_until_reset
      }.to_json ]
    ]
  end
end
