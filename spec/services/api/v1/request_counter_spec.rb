require 'rails_helper'

RSpec.describe Api::V1::RequestCounter do
  let(:session) { {} }
  let(:counter) { described_class.new(session) }

  describe '#initialize' do
    it 'initializes with default values when session is empty' do
      # Verify initial state
      expect(session[:api_requests_count]).to be_nil
      expect(session[ApiRequestLimiter::RESET_TIME_KEY]).to be_nil

      # Initialize counter
      counter

      # Verify final state
      expect(session[:api_requests_count]).to eq(0)
      expect(session[ApiRequestLimiter::RESET_TIME_KEY]).to be_within(2).of(1.hour.from_now.to_i)
    end

    it 'uses existing session values when present' do
      session[:api_requests_count] = 3
      reset_time = 1.hour.from_now.to_i
      session[ApiRequestLimiter::RESET_TIME_KEY] = reset_time

      counter
      expect(session[:api_requests_count]).to eq(3)
      expect(session[ApiRequestLimiter::RESET_TIME_KEY]).to eq(reset_time)
    end
  end

  describe '#increment' do
    before { counter } # ensure initialized

    it 'increments the request count' do
      expect { counter.increment }.to change { session[:api_requests_count] }.from(0).to(1)
    end

    it 'returns the new count' do
      session[:api_requests_count] = 2
      expect(counter.increment).to eq(3)
    end
  end

  describe '#current_count' do
    it 'returns 0 when no requests made' do
      expect(counter.current_count).to eq(0)
    end

    it 'returns the current request count' do
      counter # ensure initialized
      session[:api_requests_count] = 3
      expect(counter.current_count).to eq(3)
    end
  end

  describe '#limit_exceeded?' do
    before { counter } # ensure initialized

    context 'when count is below limit' do
      before { session[:api_requests_count] = ApiRequestLimiter::MAX_REQUESTS - 1 }

      it 'returns false' do
        expect(counter.limit_exceeded?).to be false
      end
    end

    context 'when count equals limit' do
      before { session[:api_requests_count] = ApiRequestLimiter::MAX_REQUESTS }

      it 'returns true' do
        expect(counter.limit_exceeded?).to be true
      end
    end

    context 'when count exceeds limit' do
      before { session[:api_requests_count] = ApiRequestLimiter::MAX_REQUESTS + 1 }

      it 'returns true' do
        expect(counter.limit_exceeded?).to be true
      end
    end
  end

  describe '#reset_if_expired' do
    before { counter } # ensure initialized

    context 'when reset time has passed' do
      before do
        session[:api_requests_count] = 3
        session[ApiRequestLimiter::RESET_TIME_KEY] = 1.hour.ago.to_i
      end

      it 'resets the counter' do
        # Store initial values
        initial_count = session[:api_requests_count]
        initial_reset_time = session[ApiRequestLimiter::RESET_TIME_KEY]

        # Reset
        counter.reset_if_expired

        # Verify changes
        expect(session[:api_requests_count]).to eq(0)
        expect(session[ApiRequestLimiter::RESET_TIME_KEY]).to be > initial_reset_time
        expect(session[ApiRequestLimiter::RESET_TIME_KEY]).to be_within(2).of(1.hour.from_now.to_i)
      end
    end

    context 'when reset time has not passed' do
      before do
        session[:api_requests_count] = 3
        session[ApiRequestLimiter::RESET_TIME_KEY] = 1.hour.from_now.to_i
      end

      it 'does not reset the counter' do
        expect { counter.reset_if_expired }
          .not_to change { session[:api_requests_count] }
      end

      it 'does not update the reset time' do
        expect { counter.reset_if_expired }
          .not_to change { session[ApiRequestLimiter::RESET_TIME_KEY] }
      end
    end
  end

  describe '#remaining_requests' do
    before { counter } # ensure initialized

    it 'returns max_requests when no requests made' do
      expect(counter.remaining_requests).to eq(ApiRequestLimiter::MAX_REQUESTS)
    end

    it 'returns correct remaining requests' do
      session[:api_requests_count] = 3
      expect(counter.remaining_requests).to eq(ApiRequestLimiter::MAX_REQUESTS - 3)
    end

    it 'returns 0 when limit exceeded' do
      session[:api_requests_count] = ApiRequestLimiter::MAX_REQUESTS + 1
      expect(counter.remaining_requests).to eq(0)
    end
  end
end
