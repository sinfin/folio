# frozen_string_literal: true

class Dummy::Mailer::FooterComponent < ApplicationComponent
  def initialize(site:)
    @site = site
  end
end
