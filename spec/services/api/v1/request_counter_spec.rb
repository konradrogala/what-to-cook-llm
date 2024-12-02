require 'rails_helper'

RSpec.describe Api::V1::RequestCounter do
  let(:session) { {} }
  let(:counter) { described_class.new(session) }
  let(:max_requests) { 5 }

  describe '#initialize' do
    it 'initializes with default values when session is empty' do
      expect { counter }.to change { session['api_requests_count'] }.from(nil).to(0)
      expect(session['api_requests_reset_time']).to be_within(1).of(1.hour.from_now.to_i)
    end

    it 'uses existing session values when present' do
      session['api_requests_count'] = 3
      reset_time = 1.hour.from_now.to_i
      session['api_requests_reset_time'] = reset_time

      counter
      expect(session['api_requests_count']).to eq(3)
      expect(session['api_requests_reset_time']).to eq(reset_time)
    end
  end

  describe '#increment' do
    it 'increments the request count' do
      expect { counter.increment }.to change { session['api_requests_count'] }.by(1)
    end

    it 'returns the new count' do
      session['api_requests_count'] = 2
      expect(counter.increment).to eq(3)
    end
  end

  describe '#current_count' do
    it 'returns 0 when no requests made' do
      expect(counter.current_count).to eq(0)
    end

    it 'returns the current request count' do
      session['api_requests_count'] = 3
      expect(counter.current_count).to eq(3)
    end
  end

  describe '#limit_exceeded?' do
    context 'when count is below limit' do
      before { session['api_requests_count'] = max_requests - 1 }

      it 'returns false' do
        expect(counter.limit_exceeded?).to be false
      end
    end

    context 'when count equals limit' do
      before { session['api_requests_count'] = max_requests }

      it 'returns true' do
        expect(counter.limit_exceeded?).to be true
      end
    end

    context 'when count exceeds limit' do
      before { session['api_requests_count'] = max_requests + 1 }

      it 'returns true' do
        expect(counter.limit_exceeded?).to be true
      end
    end
  end

  describe '#reset_if_expired' do
    context 'when reset time has passed' do
      before do
        session['api_requests_count'] = 3
        session['api_requests_reset_time'] = 1.hour.ago.to_i
      end

      it 'resets the counter' do
        expect { counter.reset_if_expired }
          .to change { session['api_requests_count'] }.from(3).to(0)
      end

      it 'updates the reset time' do
        expect { counter.reset_if_expired }
          .to change { session['api_requests_reset_time'] }
        expect(session['api_requests_reset_time']).to be_within(1).of(1.hour.from_now.to_i)
      end
    end

    context 'when reset time has not passed' do
      before do
        session['api_requests_count'] = 3
        reset_time = 1.hour.from_now.to_i
        session['api_requests_reset_time'] = reset_time
      end

      it 'does not reset the counter' do
        expect { counter.reset_if_expired }
          .not_to change { session['api_requests_count'] }
      end

      it 'does not update the reset time' do
        expect { counter.reset_if_expired }
          .not_to change { session['api_requests_reset_time'] }
      end
    end
  end

  describe '#remaining_requests' do
    it 'returns max_requests when no requests made' do
      expect(counter.remaining_requests).to eq(max_requests)
    end

    it 'returns correct remaining requests' do
      session['api_requests_count'] = 3
      expect(counter.remaining_requests).to eq(max_requests - 3)
    end

    it 'returns 0 when limit exceeded' do
      session['api_requests_count'] = max_requests + 1
      expect(counter.remaining_requests).to eq(0)
    end
  end
end
