# frozen_string_literal: true

class Dummy::Mailer::FooterMenuComponent < Dummy::Mailer::BaseComponent
  def initialize(site:, menu: nil)
    @site = site
    @menu = menu || Dummy::Menu::Footer.find_by(site: @site)
  end

  def render?
    @menu.present?
  end
end
