# frozen_string_literal: true

class Folio::Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :site
  attribute :request_id, :user_agent, :ip_address, :url

  # resets { Time.zone = nil }

  def site
    super || master_site
  end

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

  def master_site
    @master_site ||= Folio.main_site
  end

  def site_is_master?
    master_site.id == site.try(:id)
  end
end
