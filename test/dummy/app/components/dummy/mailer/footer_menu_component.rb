# frozen_string_literal: true

class Dummy::Mailer::FooterMenuComponent < ApplicationComponent
  def initialize(site:, menu: nil)
    @site = site
    @menu = menu
  end

  def menu
    @menu ||= Folio::Menu.where(type: "Dummy::Menu::Footer").first
  end
end
