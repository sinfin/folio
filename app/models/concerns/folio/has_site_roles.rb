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

  class_methods do
    def roles_for_select(site:, selectable_roles: nil)
      roles = site.available_user_roles
      roles = roles & selectable_roles if selectable_roles.present?

      roles.map do |role|
        [human_role_name(role), role]
      end
    end

    def human_role_name(role)
      I18n.t("folio.site.roles.#{role}")
    end
  end

  def set_roles_for(site:, roles:)
    ulf = user_link_for(site:) || create_site_link(site:)
    ulf.roles = roles.collect(&:to_s)

    ulf.valid?
  end

  def roles_for(site:)
    user_link_for(site:)&.roles || []
  end

  def user_link_for(site:)
    @site_links ||= {}
    @site_links[site.domain] ||= site_user_links.where(site:).first
  end

  def has_role?(site:, role:)
    roles_for(site:).include?(role.to_s)
  end

  def has_any_roles?(site:, roles:)
    roles.any? { |role_to_check| roles_for(site:).include?(role_to_check.to_s) }
  end

  def has_all_roles?(site:, roles:)
    roles.all? { |role_to_check| roles_for(site:).include?(role_to_check.to_s) }
  end

  def human_role_names(site:)
    roles_for(site:).map do |role_for_name|
      self.class.human_role_name(role_for_name)
    end
  end

  private
    def validate_site_roles
      site_user_links.each do |user_site_link|
        if user_site_link.invalid? && user_site_link.errors[:roles].present?
          errors.add :site_roles, user_site_link.errors[:roles].first
        end
      end
    end

    def create_site_link(site:)
      site_user_links.create(site:)
      @site_links ||= {}
      ulf = site_user_links.build(site:)
      @site_links[site.domain] = ulf
    end
end
