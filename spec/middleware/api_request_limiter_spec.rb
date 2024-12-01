require "rails_helper"

RSpec.describe ApiRequestLimiter do
  let(:app) { ->(env) { [ 201, env, "app" ] } }
  let(:middleware) { described_class.new(app) }
  let(:env) do
    {
      "REQUEST_PATH" => "/api/v1/recipes",
      "REQUEST_METHOD" => "POST",
      "HTTP_ACCEPT" => "application/json",
      "rack.session" => session
    }
  end
  let(:session) { {} }

  describe "#call" do
    context "when under the request limit" do
      let(:session) { { api_requests_count: 2 } }

      it "allows the request and increases the counter" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(201)
        expect(session[:api_requests_count]).to eq(3)
      end
    end

    context "when at the request limit" do
      let(:session) { { api_requests_count: 5 } }

      it "blocks the request" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(429)
      end
    end

    context "when not an API request" do
      let(:env) do
        {
          "REQUEST_PATH" => "/health",
          "REQUEST_METHOD" => "GET",
          "rack.session" => session
        }
      end

      it "skips the middleware" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(201)
        expect(session[:api_requests_count]).to be_nil
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
