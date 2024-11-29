class ApiRequestLimiter
  MAX_REQUESTS = 5

  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip middleware for non-API requests
    return @app.call(env) unless api_request?(env)

    session = env["rack.session"]
    session[:api_requests_count] ||= 0

    Rails.logger.info "Current request count: #{session[:api_requests_count]}"

    if session[:api_requests_count] >= MAX_REQUESTS
      Rails.logger.warn "Rate limit exceeded"
      return rate_limit_response
    end

    # Call the app first
    status, headers, response = @app.call(env)

    # Only increment counter if request was successful
    if status == 201
      session[:api_requests_count] += 1
      Rails.logger.info "Incrementing count to: #{session[:api_requests_count]}"
    end

    [ status, headers, response ]
  end

  private

  def api_request?(env)
    env["PATH_INFO"].start_with?("/api/v1/recipes") &&
    env["REQUEST_METHOD"] == "POST" &&
    env["HTTP_ACCEPT"]&.include?("application/json")
  end

  def rate_limit_response
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Rate limit exceeded. Maximum 5 requests per session allowed." }.to_json ]
    ]
  end
end
