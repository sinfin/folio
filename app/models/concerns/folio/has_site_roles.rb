# frozen_string_literal: true

module Folio::HasSiteRoles
  extend ActiveSupport::Concern

  included do
    validate :validate_site_roles

    has_many :site_user_links, class_name: "Folio::SiteUserLink",
                               foreign_key: :user_id,
                               inverse_of: :user,
                               dependent: :destroy
    has_many :sites, through: :site_user_links,
                     source: :site
  end

  def set_roles_for_site(site, roles)
    ulf = user_link_for(site)
    if ulf.blank?
      @site_links ||= {}
      ulf = site_user_links.build(site:)
      @site_links[site.domain] = ulf
    end

    ulf.roles = roles.collect(&:to_s)
    ulf.valid?
  end

  def roles_for_site(site)
    user_link_for(site)&.roles || []
  end

  def user_link_for(site)
    @site_links ||= {}
    @site_links[site.domain] ||= site_user_links.where(site:).first
  end

  def has_site_role?(role_to_check, site:)
    roles_for_site(site).include?(role_to_check.to_s)
  end

  private
    def validate_site_roles
      site_user_links.each do |user_site_link|
        if user_site_link.invalid? && user_site_link.errors[:roles].present?
          errors.add :site_roles, user_site_link.errors[:roles].first
        end
      end
    end
end
