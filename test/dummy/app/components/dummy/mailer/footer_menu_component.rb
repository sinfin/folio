# frozen_string_literal: true

class Dummy::Mailer::FooterMenuComponent < ApplicationComponent
  def initialize(site:)
    @site = site
  end

  def current_footer_menu
    @current_footer_menu ||= Folio::Menu.where(type: "Dummy::Menu::Footer").first
  end

  def menu
    @menu ||= current_footer_menu
  end
end
