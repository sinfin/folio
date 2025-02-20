# frozen_string_literal: true

# Overwrite .env.sample default variables in tests to skip checks in models
[
  "JWPLAYER_API_KEY",
  "JWPLAYER_API_V1_SECRET",
  "JWPLAYER_API_V2_SECRET",
  "MUX_API_KEY",
  "MUX_API_ID",
  "MUX_API_SECRET",
].each do |env_variable|
  ENV[env_variable] = "mock-#{env_variable}" if ENV[env_variable] == "find-me-in-vault"
end
