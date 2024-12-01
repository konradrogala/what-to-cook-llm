require "rails_helper"

RSpec.describe ApiRequestLimiter do
  let(:app) { ->(env) { [201, env, "app"] } }
  let(:middleware) { ApiRequestLimiter.new(app) }
  let(:session) { {} }
  let(:env) do
    {
      "rack.session" => session,
      "PATH_INFO" => "/api/v1/recipes",
      "REQUEST_METHOD" => "POST",
      "HTTP_ACCEPT" => "application/json"
    }
  end

  describe "#call" do
    context "when under the request limit" do
      it "allows the request and increases the counter" do
        session[:api_requests_count] = 2
        status, _, _ = middleware.call(env)

        expect(status).to eq(201)
        expect(session[:api_requests_count]).to eq(3)
      end
    end

    context "when at the request limit" do
      it "blocks the request" do
        session[:api_requests_count] = ApiRequestLimiter::MAX_REQUESTS
        status, _, response = middleware.call(env)

        expect(status).to eq(429)
        expect(JSON.parse(response.first)).to include(
          "error" => "Rate limit exceeded. Maximum 5 requests per session allowed."
        )
      end
    end

    context "when request is not to the API endpoint" do
      before do
        env["PATH_INFO"] = "/some/other/path"
      end

      it "does not change the counter" do
        session[:api_requests_count] = 2
        status, _, _ = middleware.call(env)

        expect(status).to eq(201)
        expect(session[:api_requests_count]).to eq(2)
      end
    end

    context "when session is new" do
      it "initializes the counter to 1 after first request" do
        status, _, _ = middleware.call(env)

        expect(status).to eq(201)
        expect(session[:api_requests_count]).to eq(1)
      end
    end
  end
end
