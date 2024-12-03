require 'rails_helper'

RSpec.describe ApiRequestLimiter do
  let(:app) { ->(env) { [ status, headers, response ] } }
  let(:middleware) { described_class.new(app) }
  let(:status) { 201 }
  let(:headers) { { 'Content-Type' => 'application/json' } }
  let(:response) { [ { 'recipe' => 'test' }.to_json ] }
  let(:env) do
    {
      'REQUEST_PATH' => '/api/v1/recipes',
      'REQUEST_METHOD' => 'POST',
      'HTTP_ACCEPT' => 'application/json',
      'rack.session' => {}
    }
  end

  shared_examples 'rate limited response' do |response_type|
    it "modifies the #{response_type} response to include limit info" do
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

  describe '#call' do
    context 'when request is not an API request' do
      context 'with different paths' do
        ['other/path', 'api/v2/recipes', 'api/v1/other'].each do |path|
          it "skips #{path} requests" do
            env['REQUEST_PATH'] = "/#{path}"
            status, _, _ = middleware.call(env)
            expect(status).to eq(201)
          end
        end
      end

      context 'with different HTTP methods' do
        ['GET', 'PUT', 'DELETE'].each do |method|
          it "skips non-POST #{method} requests" do
            env['REQUEST_METHOD'] = method
            status, _, _ = middleware.call(env)
            expect(status).to eq(201)
          end
        end
      end

      context 'with different Accept headers' do
        ['text/html', 'application/xml', ''].each do |accept|
          it "skips requests with #{accept.presence || 'empty'} Accept header" do
            env['HTTP_ACCEPT'] = accept
            status, _, _ = middleware.call(env)
            expect(status).to eq(201)
          end
        end
      end
    end

    context 'when request is an API request' do
      context 'with different request paths' do
        ['?param=value', '/with/additional/path'].each do |path_suffix|
          it "handles path #{path_suffix}" do
            env['REQUEST_PATH'] = "/api/v1/recipes#{path_suffix}"
            status, _, _ = middleware.call(env)
            expect(status).to eq(201)
          end
        end
      end

      context 'when limit is not exceeded' do
        it 'passes through to the app' do
          status, headers, response = middleware.call(env)
          expect(status).to eq(201)
          expect(JSON.parse(response[0])).to eq({ 'recipe' => 'test' })
        end

        it 'handles nil response' do
          allow(app).to receive(:call).and_return([201, headers, nil])
          status, _, response = middleware.call(env)
          expect(status).to eq(201)
          expect(response).to be_nil
        end

        it 'handles empty response' do
          allow(app).to receive(:call).and_return([201, headers, []])
          status, _, response = middleware.call(env)
          expect(status).to eq(201)
          expect(response).to eq([])
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
            let(:response) { [ { 'recipe' => 'test' }.to_json ] }
            it_behaves_like 'rate limited response', 'Array'
          end

          context 'with Rack::BodyProxy response' do
            let(:response) do
              body = [ { 'recipe' => 'test' }.to_json ]
              Rack::BodyProxy.new(body) { }
            end
            it_behaves_like 'rate limited response', 'Rack::BodyProxy'
          end
        end

        context 'with error response' do
          let(:status) { 422 }
          let(:response) { [ { 'error' => 'Invalid request' }.to_json ] }

          it 'does not modify error responses' do
            _, _, response = middleware.call(env)
            expect(JSON.parse(response[0])).to eq({ 'error' => 'Invalid request' })
          end
        end

        context 'with unparseable response' do
          let(:response) { [ 'Invalid JSON' ] }

          it 'returns original response on parse error' do
            _, _, response = middleware.call(env)
            expect(response[0]).to eq('Invalid JSON')
          end
        end
      end

      context 'when reset time handling' do
        it 'sets reset time when not present' do
          middleware.call(env)
          expect(env['rack.session'][described_class::RESET_TIME_KEY]).to be_present
        end

        it 'does not modify existing reset time' do
          existing_time = 1.hour.from_now.to_i
          env['rack.session'][described_class::RESET_TIME_KEY] = existing_time
          middleware.call(env)
          expect(env['rack.session'][described_class::RESET_TIME_KEY]).to eq(existing_time)
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

    it 'handles edge case when reset time is in the past' do
      reset_time = Time.now.to_i - 3600 # 1 hour ago
      _, _, response = middleware.send(:rate_limit_response, reset_time)
      body = JSON.parse(response[0])
      expect(body['minutes_until_reset']).to eq(0)
    end
  end
end
