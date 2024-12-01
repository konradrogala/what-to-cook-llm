# Configure the session store
Rails.application.config.session_store :cookie_store,
  key: "_what_to_cook_llm_session",
  expire_after: 24.hours
