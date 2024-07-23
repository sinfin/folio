# frozen_string_literal: true

class Dummy::Mailer::LayoutComponent < Dummy::Mailer::BaseComponent
  def initialize(site:, preview_text: nil)
    @site = site
    @preview_text = preview_text
  end
end
