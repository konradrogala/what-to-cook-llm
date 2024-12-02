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
  let(:counter) { instance_double(Api::V1::RequestCounter) }

  before do
    allow(Api::V1::RequestCounter).to receive(:new).with(session).and_return(counter)
    allow(counter).to receive(:reset_if_expired)
    allow(counter).to receive(:current_count)
  end

  describe "#call" do
    context "when under the request limit" do
      before do
        allow(counter).to receive(:limit_exceeded?).and_return(false)
      end

      it "allows the request" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(201)
      end

      it "checks and resets the counter if expired" do
        middleware.call(env)
        expect(counter).to have_received(:reset_if_expired)
      end
    end

    context "when at the request limit" do
      before do
        allow(counter).to receive(:limit_exceeded?).and_return(true)
      end

      it "blocks the request" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(429)
      end

      it "includes rate limit information in the response" do
        reset_time = 1.hour.from_now.to_i
        session[described_class::RESET_TIME_KEY] = reset_time
        _, _, response = middleware.call(env)
        json_response = JSON.parse(response.first)

        expect(json_response["error"]).to include("Rate limit exceeded")
        expect(json_response["remaining_requests"]).to eq(0)
        expect(json_response["reset_in_minutes"]).to be_present
        expect(json_response["message"]).to include("Please try again")
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
        expect(Api::V1::RequestCounter).not_to have_received(:new)
      end
    end

    context "when request becomes rate limited after processing" do
      before do
        # First check passes
        allow(counter).to receive(:limit_exceeded?).and_return(false, true)
      end

      it "blocks the request" do
        status, _, _ = middleware.call(env)
        expect(status).to eq(429)
      end
    end
  end
end
