# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :site
  attribute :request_id, :user_agent, :ip_address, :url

  # resets { Time.zone = nil }

  def user=(user)
    super
    # Time.zone = user.time_zone
  end

  if Rails.env.test?
    alias :original_reset :reset

    def reset
      run_callbacks :reset do
        # self.attributes = {}
      end
    end
  end

  def to_h
    attributes
  end
end
