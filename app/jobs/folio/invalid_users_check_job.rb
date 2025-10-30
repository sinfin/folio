# frozen_string_literal: true

class Folio::InvalidUsersCheckJob < Folio::ApplicationJob
  queue_as :slow

  adapter_aware_sidekiq_options(
    lock: :until_and_while_executing,
    lock_ttl: 5.minutes.to_i,
    on_conflict: {
      client: :reject,
      server: :raise
    }
  )

  class InvalidUsersError < StandardError
  end

  def perform
    errors = []

    Folio::User.includes(:auth_site, :authentications, site_user_links: :site).find_each(batch_size: 500) do |user|
      next if user.valid?

      invalid_fields = user.errors.messages.map do |field, messages|
        "#{field}: #{messages.join(", ")}"
      end.join("; ")

      errors << "[##{user.id}] #{invalid_fields}"
    end

    raise InvalidUsersError, errors.join("\n") if errors.any?
  end
end
