# frozen_string_literal: true

class Dummy::Ui::FooterCell < ApplicationCell
  def menu
    @menu ||= Dummy::Menu::Footer.instance(fail_on_missing: false)
  end

  def social_links
    allowed = %w[facebook instagram linkedin pinterest twitter youtube]
    current_site.social_links.slice(*allowed)
  end
end
