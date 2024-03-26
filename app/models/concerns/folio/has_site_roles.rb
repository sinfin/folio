# frozen_string_literal: true

module Folio::HasSiteRoles
  extend ActiveSupport::Concern

  included do
    validate :validate_site_roles
    validate :validate_site_link_uniqueness

    has_many :site_user_links, class_name: "Folio::SiteUserLink",
                               foreign_key: :user_id,
                               inverse_of: :user,
                               dependent: :destroy
    has_many :sites, through: :site_user_links,
                     source: :site

    scope :with_unscoped_roles, -> (roles) { where(id: Folio::SiteUserLink.by_roles(roles).select(:user_id)) }
    scope :with_site_roles, -> (site:, roles:) { joins(:site_user_links).merge(Folio::SiteUserLink.by_site(site).by_roles(roles)) }
    scope :without_site_roles, -> (site:, roles:) { joins(:site_user_links).merge(Folio::SiteUserLink.by_site(site).without_roles(roles)) }
  end

  class_methods do
    def roles_for_select(site:, selectable_roles: nil)
      roles = site.available_user_roles_ary
      roles = roles & selectable_roles if selectable_roles.present?

      roles.map do |role|
        [human_role_name(role), role]
      end
    end

    def human_role_name(role)
      Folio::Site.human_attribute_name("roles/#{role}")
    end
  end

  def site_user_links_attributes=(attributes)
    attributes.each_value do |link_attributes|
      next if (site = Folio::Site.find(link_attributes["site_id"].to_i.abs)).nil?

      if link_attributes["site_id"].to_i < 0
        destroy_site_link(site:)
      else
        set_roles_for(site:, roles: link_attributes["roles"] || [])
      end
    end
  end

  def set_roles_for(site:, roles:)
    ulf = user_link_for(site:) || build_site_link(site:)
    ulf.roles = roles.collect(&:to_s).uniq

    if ulf.valid?
      ulf.save if ulf.persisted?
      true
    else
      self.errors.add(:site_roles, ulf.errors.full_messages)
      false
    end
  end

  def set_roles_for!(site:, roles:)
    set_roles_for(site:, roles:)
    save!
  end

  def destroy_site_link(site:)
    ulf = user_link_for(site:)
    if ulf
      ulf.roles = []
      ulf.destroy
    end
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

    def validate_site_link_uniqueness
      sets = site_user_links.group_by(&:site_id)

      sets.each_pair do |site_id, links|
        if links.size > 1
          errors.add :site_roles, "Duplicitní přiřazení webu '#{Folio::Site.find(site_id).domain}'."
        end
      end
    end

    def build_site_link(site:)
      @site_links ||= {}
      ulf = site_user_links.build(site:)
      @site_links[site.domain] = ulf
    end
end
