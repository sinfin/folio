# frozen_string_literal: true

module Folio
  def self.main_site
    if Rails.application.config.eager_load
      @main_site ||= Dummy::Site.first
    else
      Dummy::Site.first
    end
  end
end
