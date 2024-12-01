# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true,
      max_age: 3600,
      expose: [ "Set-Cookie" ]
  end
end

# Configure session cookie settings
Rails.application.config.session_store :cookie_store,
  key: "_what_to_cook_session",
  same_site: :lax,
  secure: Rails.env.production?
