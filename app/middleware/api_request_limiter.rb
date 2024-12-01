class ApiRequestLimiter
  MAX_REQUESTS = 5
  REQUEST_KEY = "api_request_processed"

  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip middleware for non-API requests
    return @app.call(env) unless api_request?(env)

    request = Rack::Request.new(env)
    session = request.session
    session[:api_requests_count] ||= 0

    # Check if this specific request has already been processed
    if env[REQUEST_KEY]
      return @app.call(env)
    end

    Rails.logger.info "[MIDDLEWARE] Request path: #{request.path}"
    Rails.logger.info "[MIDDLEWARE] Request method: #{request.request_method}"
    Rails.logger.info "[MIDDLEWARE] Accept header: #{env['HTTP_ACCEPT']}"
    Rails.logger.info "[MIDDLEWARE] Initial count: #{session[:api_requests_count]}"

    if session[:api_requests_count] >= MAX_REQUESTS
      Rails.logger.warn "[MIDDLEWARE] Rate limit exceeded"
      return rate_limit_response
    end

    # Mark this request as processed
    env[REQUEST_KEY] = true

    # Increment counter before processing
    session[:api_requests_count] += 1
    Rails.logger.info "[MIDDLEWARE] Incremented count to: #{session[:api_requests_count]}"

    # Call the app
    status, headers, response = @app.call(env)

    # Decrement counter if request failed
    if status != 201
      session[:api_requests_count] -= 1
      Rails.logger.info "[MIDDLEWARE] Request failed, decremented count: #{session[:api_requests_count]}"
    end

    Rails.logger.info "[MIDDLEWARE] Response status: #{status}"
    Rails.logger.info "[MIDDLEWARE] Final count: #{session[:api_requests_count]}"

    [status, headers, response]
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

  def rate_limit_response
    [
      429,
      { "Content-Type" => "application/json" },
      [{ 
        error: "Rate limit exceeded. Maximum 5 requests per session allowed.",
        remaining_requests: 0
      }.to_json]
    ]
  end
end
