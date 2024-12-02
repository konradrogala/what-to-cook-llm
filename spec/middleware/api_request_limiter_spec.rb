require 'rails_helper'

RSpec.describe ApiRequestLimiter do
  let(:app) { ->(_env) { [ status, headers, [ response_body ] ] } }
  let(:middleware) { described_class.new(app) }
  let(:status) { 200 }
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:response_body) { { recipe: "test" }.to_json }
  let(:session) { {} }
  let(:env) do
    {
      "REQUEST_PATH" => "/api/v1/recipes",
      "REQUEST_METHOD" => "POST",
      "HTTP_ACCEPT" => "application/json",
      "rack.session" => session
    }
  end

  let(:counter) { instance_double(Api::V1::RequestCounter) }

  before do
    allow(Api::V1::RequestCounter).to receive(:new).and_return(counter)
    allow(counter).to receive(:reset_if_expired)
    allow(counter).to receive(:current_count)
  end

  describe '#call' do
    context 'when request is not an API request' do
      let(:env) { { "REQUEST_PATH" => "/other/path", "rack.session" => session } }

      it 'passes through to the app' do
        status, _, response = middleware.call(env)
        expect(status).to eq(200)
        expect(response).to eq([ response_body ])
      end
    end

    context 'when request is an API request' do
      context 'when limit is not exceeded' do
        before do
          allow(counter).to receive(:limit_exceeded?).and_return(false)
        end

        it 'passes through to the app' do
          status, _, response = middleware.call(env)
          expect(status).to eq(200)
          expect(JSON.parse(response[0])).to eq({ "recipe" => "test" })
        end
      end

      context 'when limit is exceeded' do
        before do
          allow(counter).to receive(:limit_exceeded?).and_return(true)
          session[described_class::RESET_TIME_KEY] = 1.hour.from_now.to_i
        end

        context 'with successful response' do
          let(:status) { 201 }

          context 'with Array response' do
            let(:response_body) { [{ 'recipe' => 'test' }.to_json] }

            it 'modifies the response to include limit info' do
              status, _, response = middleware.call(env)
              body = JSON.parse(response[0])
              
              expect(status).to eq(201)
              expect(body).to include(
                'recipe' => 'test',
                'limit_reached' => true,
                'message' => 'You have reached the maximum number of requests for this session.',
                'remaining_requests' => 0
              )
            end
          end

          context 'with Rack::BodyProxy response' do
            let(:response_body) { Rack::BodyProxy.new([{ 'recipe' => 'test' }.to_json]) { } }

            it 'modifies the response to include limit info' do
              status, _, response = middleware.call(env)
              body = JSON.parse(response[0])
              
              expect(status).to eq(201)
              expect(body).to include(
                'recipe' => 'test',
                'limit_reached' => true,
                'message' => 'You have reached the maximum number of requests for this session.',
                'remaining_requests' => 0
              )
            end
          end
        end

        context 'with error response' do
          let(:status) { 422 }
          let(:response_body) { { error: "Invalid input" }.to_json }

          it 'does not modify error responses' do
            status, _, response = middleware.call(env)
            expect(status).to eq(422)
            expect(JSON.parse(response[0])).to eq({ "error" => "Invalid input" })
          end
        end

        context 'with unparseable response' do
          let(:response_body) { 'invalid json' }

          it 'returns original response on parse error' do
            status, _, response = middleware.call(env)
            expect(status).to eq(200)
            expect(response[0]).to eq('invalid json')
          end
        end
      end
    end
  end

  describe '#rate_limit_response' do
    let(:reset_time) { 1.hour.from_now.to_i }

    it 'returns correct rate limit response format' do
      status, headers, response = middleware.send(:rate_limit_response, reset_time)
      body = JSON.parse(response[0])

      expect(status).to eq(429)
      expect(headers).to include("Content-Type" => "application/json")
      expect(body).to include(
        "error" => "Rate limit exceeded. Maximum #{described_class::MAX_REQUESTS} requests per hour allowed.",
        "remaining_requests" => 0
      )
      expect(body["minutes_until_reset"]).to be_within(1).of(60)
    end
  end
end
