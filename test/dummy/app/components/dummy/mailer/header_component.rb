# frozen_string_literal: true

class Dummy::Mailer::HeaderComponent < ApplicationComponent
  def initialize(site:, logo: false)
    @site = site
    @logo = logo
  end
end
