# frozen_string_literal: true

class Dummy::Ui::FooterCell < ApplicationCell
  def menu
    @menu ||= current_footer_menu
  end

  def social_links
    allowed = %w[facebook instagram linkedin pinterest twitter youtube]
    current_site.social_links.slice(*allowed).select { |key, val| val.present? }
  end
end
