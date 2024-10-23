# frozen_string_literal: true

class Folio::InvalidUsersCheckJob < Folio::ApplicationJob
  queue_as :slow

  class InvalidUsersError < StandardError
  end

  def perform
    errors = []
    Folio::User.find_each do |user|
      next if user.valid?

      invalid_fields = user.errors.messages.map do |field, messages|
        "#{field}: #{messages.join(", ")}"
      end.join("; ")

      errors << "[##{user.id}] #{invalid_fields}"
    end

    raise InvalidUsersError, errors.join("\n") if errors.any?
  end
end
