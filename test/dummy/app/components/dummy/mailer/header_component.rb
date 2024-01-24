# frozen_string_literal: true

class Dummy::Mailer::HeaderComponent < ApplicationComponent
  def initialize(site:)
    @site = site
  end
end
