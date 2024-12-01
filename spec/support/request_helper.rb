module RequestHelper
  def json_response
    JSON.parse(response.body)
  end

  def setup_api_session
    if defined?(@request)
      # For controller tests
      @request.session[:api_requests_count] = 0
    else
      # For request tests
      allow_any_instance_of(ActionDispatch::Request).to receive(:session).and_return(
        ActionController::TestSession.new(api_requests_count: 0)
      )
    end
  end
end

RSpec.configure do |config|
  config.include RequestHelper, type: :request
  config.include RequestHelper, type: :controller

  config.before(:each, type: :request) do
    setup_api_session
  end

  config.before(:each, type: :controller) do
    setup_api_session
  end
end
