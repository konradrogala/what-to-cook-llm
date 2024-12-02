require 'rails_helper'

RSpec.describe ApiRequestLimiter do
  let(:app) { ->(env) { [status, headers, response] } }
  let(:middleware) { described_class.new(app) }
  let(:status) { 201 }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:response) { [{ 'recipe' => 'test' }.to_json] }
  let(:env) do
    {
      'REQUEST_PATH' => '/api/v1/recipes',
      'REQUEST_METHOD' => 'POST',
      'HTTP_ACCEPT' => 'application/json',
      'rack.session' => {}
    }
  end

  describe '#call' do
    context 'when request is not an API request' do
      let(:env) { { 'REQUEST_PATH' => '/other/path', 'rack.session' => {} } }

      it 'passes through to the app' do
        status, headers, response = middleware.call(env)
        expect(status).to eq(201)
      end
    end

    context 'when request is an API request' do
      context 'when limit is not exceeded' do
        it 'passes through to the app' do
          status, headers, response = middleware.call(env)
          expect(status).to eq(201)
          expect(JSON.parse(response[0])).to eq({ 'recipe' => 'test' })
        end
      end

      context 'when limit is exceeded' do
        before do
          counter = Api::V1::RequestCounter.new(env['rack.session'])
          described_class::MAX_REQUESTS.times { counter.increment }
        end

        context 'with successful response' do
          let(:status) { 201 }

          context 'with standard Array response' do
            let(:response) { [{ 'recipe' => 'test' }.to_json] }

            it 'modifies the response to include limit info' do
              _, _, modified_response = middleware.call(env)
              body = JSON.parse(modified_response[0])
              
              expect(body).to include(
                'recipe' => 'test',
                'limit_reached' => true,
                'message' => 'You have reached the maximum number of requests for this session.',
                'remaining_requests' => 0
              )
            end
          end

          context 'with Rack::BodyProxy response' do
            let(:response) do
              body = [{ 'recipe' => 'test' }.to_json]
              Rack::BodyProxy.new(body) { }
            end

            it 'modifies the response to include limit info' do
              _, _, modified_response = middleware.call(env)
              body = JSON.parse(modified_response[0])
              
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
          let(:response) { [{ 'error' => 'Invalid request' }.to_json] }

          it 'does not modify error responses' do
            _, _, response = middleware.call(env)
            expect(JSON.parse(response[0])).to eq({ 'error' => 'Invalid request' })
          end
        end

        context 'with unparseable response' do
          let(:response) { ['Invalid JSON'] }

          it 'returns original response on parse error' do
            _, _, response = middleware.call(env)
            expect(response[0]).to eq('Invalid JSON')
          end
        end
      end
    end
  end

  describe '#rate_limit_response' do
    it 'returns correct rate limit response format' do
      reset_time = Time.now.to_i + 3600 # 1 hour from now
      status, headers, response = middleware.send(:rate_limit_response, reset_time)

      expect(status).to eq(429)
      expect(headers).to include('Content-Type' => 'application/json')

      body = JSON.parse(response[0])
      expect(body).to include(
        'error' => 'Rate limit exceeded. Maximum 5 requests per hour allowed.',
        'remaining_requests' => 0
      )
      expect(body['minutes_until_reset']).to be_between(59, 60)
    end
  end
end
