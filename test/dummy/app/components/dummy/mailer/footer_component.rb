# frozen_string_literal: true

class Dummy::Mailer::FooterComponent < ApplicationComponent
  def initialize(site:, logo: false, menu: nil)
    @site = site
    @logo = logo
    @menu = menu
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

  def contact_link_with_fallback_tag(key, value)
    base_class = "d-mailer-footer__contact-detail"

    if key == :email
      { tag: :a, href: "mailto:#{value}", class: base_class }
    elsif key == :phone
      { tag: :a, href: "tel:#{value}", class: base_class }
    else
      { class: base_class }
    end
  end

  def current_footer_menu?
    @menu || Folio::Menu.where(type: "Dummy::Menu::Footer").exists?
  end
end
