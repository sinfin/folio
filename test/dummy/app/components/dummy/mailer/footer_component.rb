# frozen_string_literal: true

class Dummy::Mailer::FooterComponent < ApplicationComponent
  def initialize(site:, logo: false)
    @site = site
    @logo = logo
  end

  def contact_details
    h = {}

    %i[address phone email].each do |key|
      if @site.send(key).present?
        h[key] = @site.send(key)
      end
    end

    h
  end

  def current_footer_menu
    @current_footer_menu ||= Folio::Menu.where(type: "Dummy::Menu::Footer").first
  end

  def menu
    @menu ||= current_footer_menu
  end
end
