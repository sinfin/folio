# frozen_string_literal: true

class Dummy::Mailer::LayoutComponent < ApplicationComponent
  def initialize(site:)
    @site = site
  end
end
