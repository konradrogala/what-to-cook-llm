class ApiRequestLimiter
  MAX_REQUESTS = 5
  RESET_TIME_KEY = "api_requests_reset_time"

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless api_request?(env)

    request = Rack::Request.new(env)
    counter = Api::V1::RequestCounter.new(request.session)
    counter.reset_if_expired

    status, headers, response = @app.call(env)

    if counter.limit_exceeded?
      ensure_reset_time(request.session)
      response = modify_response(status, response) if success_response?(status)
    end

    [ status, headers, response ]
  end

  private

  def api_request?(env)
    path = env["REQUEST_PATH"] || env["PATH_INFO"]
    method = env["REQUEST_METHOD"]
    accept = env["HTTP_ACCEPT"]

    path&.start_with?("/api/v1/recipes") &&
      method == "POST" &&
      accept&.include?("application/json")
  end

  def success_response?(status)
    [ 200, 201 ].include?(status)
  end

  def parse_response_body(response)
    body_content = case response
    when Array
      response.first.to_s
    when Rack::BodyProxy
      response.each.to_a.join
    else
      response.to_s
    end

    JSON.parse(body_content)
  rescue JSON::ParserError => e
    Rails.logger.error "[MIDDLEWARE] Failed to parse response body: #{e.message}"
    nil
  end

  def modify_response(status, response)
    body = parse_response_body(response)
    return response unless body

    body.merge!(
      "limit_reached" => true,
      "message" => "You have reached the maximum number of requests for this session.",
      "remaining_requests" => 0
    )

    [ body.to_json ]
  end

  def ensure_reset_time(session)
    return if session[RESET_TIME_KEY]
    session[RESET_TIME_KEY] = 1.hour.from_now.to_i
  end

  def rate_limit_response(reset_time)
    minutes_until_reset = [ (reset_time - Time.now.to_i) / 60.0, 0 ].max.ceil
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
