class ApiRequestLimiter
  MAX_REQUESTS = 5

  def initialize(app)
    @app = app
  end

  def call(env)
    # Skip middleware for non-API requests
    return @app.call(env) unless api_request?(env)

    request = Rack::Request.new(env)
    session = request.session
    session[:api_requests_count] ||= 0

    Rails.logger.info "[MIDDLEWARE] Request path: #{request.path}"
    Rails.logger.info "[MIDDLEWARE] Request method: #{request.request_method}"
    Rails.logger.info "[MIDDLEWARE] Accept header: #{env['HTTP_ACCEPT']}"
    Rails.logger.info "[MIDDLEWARE] Initial count: #{session[:api_requests_count]}"
    Rails.logger.info "[MIDDLEWARE] Session object: #{session.inspect}"
    Rails.logger.info "[MIDDLEWARE] Session store: #{session.class}"

    if session[:api_requests_count] >= MAX_REQUESTS
      Rails.logger.warn "[MIDDLEWARE] Rate limit exceeded"
      return rate_limit_response
    end

    # Increment the counter before processing the request
    session[:api_requests_count] += 1
    Rails.logger.info "[MIDDLEWARE] Updated count: #{session[:api_requests_count]}"

    # Process the request
    status, headers, response = @app.call(env)

    # If request failed, decrement the counter
    if status != 201
      session[:api_requests_count] -= 1
      Rails.logger.info "[MIDDLEWARE] Request failed, reverting count: #{session[:api_requests_count]}"
    end

    [ status, headers, response ]
  end

  private

  def api_request?(env)
    path = env["REQUEST_PATH"] || env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    accept = env["HTTP_ACCEPT"]

    Rails.logger.info "[MIDDLEWARE] Checking request: path=#{path}, method=#{method}, accept=#{accept}"

    path&.start_with?("/api/") &&
      method == "POST" &&
      accept&.include?("application/json")
  end

  def rate_limit_response
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ]
    ]
  end
end
