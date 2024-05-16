# frozen_string_literal: true

class Dummy::Mailer::HeaderComponent < Dummy::Mailer::BaseComponent
  def initialize(site:)
    @site = site
  end
end
