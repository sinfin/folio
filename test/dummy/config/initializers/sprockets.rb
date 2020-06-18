# frozen_string_literal: true

# disable concurrency to fix sprockets 4 sassc segfaults
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end
