# frozen_string_literal: true

module Dummy::CurrentMethods
  extend ActiveSupport::Concern

  def current_menus
    @current_menus ||= Folio::Menu.by_site(current_site)
                                  .where(type: %w[Dummy::Menu::Header
                                                  Dummy::Menu::Footer])
                                  .to_a
  end

  def current_header_menu
    @current_header_menu ||= current_menus.find { |m| m.type == "Dummy::Menu::Header" }
  end

  def current_footer_menu
    @current_footer_menu ||= current_menus.find { |m| m.type == "Dummy::Menu::Footer" }
  end

  def current_page_singleton(klass, fail_on_missing: false)
    @current_page_singletons ||= begin
      h = {}

      Folio::Page.by_site(current_site).where(type: %w[
        Dummy::Page::Homepage
        Dummy::Page::Blog::Articles::Index
      ]).each { |p| h[p.type] = p }

      h
    end

    @current_page_singletons[klass.to_s] ||= klass.instance(fail_on_missing:, site: current_site)
  end
end
