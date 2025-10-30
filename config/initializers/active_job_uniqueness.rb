# frozen_string_literal: true

ActiveJob::Uniqueness.configure do |config|
  # Set default lock TTL to 1 minute for all jobs
  config.lock_ttl = 1.minute

  # Default conflict handling - log when a job is blocked by uniqueness
  config.on_conflict = :log
end
