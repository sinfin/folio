# frozen_string_literal: true

class Dummy::Mailer::LayoutComponent < Dummy::Mailer::BaseComponent
  def initialize(site:)
    @site = site
  end

  def preview_text
    # Preview text must be at least 90 characters long
    "Some hidden preview text. Should be minimal 90 characters long. Lorem ipsum dolor sit amet, lorem ipsum"
  end
end
