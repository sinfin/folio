# frozen_string_literal: true

class Dummy::Mailer::SocialsComponent < Dummy::Mailer::BaseComponent
  def initialize(site:)
    @site = site
  end

  def social_links
    if @site.social_links.present?
      allowed = %w[instagram linkedin twitter tiktok youtube facebook]
      @site.social_links.slice(*allowed).select { |key, val| val.present? }
    end
  end
end
