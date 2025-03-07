# frozen_string_literal: true

class Dummy::Ui::FooterComponent < ApplicationComponent
  def menu
    @menu ||= current_footer_menu
  end

  def social_links
    if Folio::Current.site.social_links.present?
      allowed = %w[instagram linkedin twitter tiktok youtube facebook linktree]
      Folio::Current.site.social_links.slice(*allowed).select { |key, val| val.present? }
    end
  end

  def contact_details
    h = {}

    %i[address phone email].each do |key|
      if Folio::Current.site.send(key).present?
        h[key] = Folio::Current.site.send(key)
      end
    end

    h
  end

  def author_link_title
    "Sinfin.digital - UX, web design, programování a kódování webových stránek a aplikací, autor open-source CMS Folio."
  end
end
