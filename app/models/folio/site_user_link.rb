# frozen_string_literal: true

class Folio::SiteUserLink < Folio::ApplicationRecord
  belongs_to :user, class_name: "Folio::User",
                    inverse_of: :site_user_links
  belongs_to :site, class_name: "Folio::Site",
                    inverse_of: :site_user_links

  validate :validate_roles_from_site

  scope :without_role, -> (role_to_check) {
    where.not("roles ? :role", role: role_to_check)
  }

  scope :without_roles, -> (roles_to_check) {
    where.not("roles ?| array[:roles]", roles: roles_to_check)
  }

  scope :by_role, -> (role_to_check) {
    where("roles ? :role", role: role_to_check)
  }

  scope :by_roles, -> (roles_to_check) {
    where("roles ?| array[:roles]", roles: roles_to_check)
  }

  scope :by_site, -> (site) { where(site:) }
  scope :by_user, -> (site) { where(user:) }

  scope :locked, -> { where(locked_at: ...Time.current) }
  scope :unlocked, -> { where(locked_at: nil) }

  def self.non_nillifiable_fields
    %w[roles]
  end

  def validate_roles_from_site
    forbidden_roles = (roles.to_a.collect(&:to_s) - site.available_user_roles_ary.to_a)
    if forbidden_roles.present?
      errors.add(:roles, :not_available_for_site, site: site.domain, roles: forbidden_roles.to_s)
    else
      normalize_site_roles
    end
  end

  def roles=(values)
    if Folio::Current.user.present? && !@disabled_roles_ability_check
      values.to_a.each do |role|
        unless Folio::Current.user.can_manage_role?(role, self.site)
          raise "Current user #{Folio::Current.user.email} cannot set_#{role}!"
        end
      end
    end

    super(values)
  end

  # keep defined order and allow only known roles
  def normalize_site_roles
    return if roles == []

    @disabled_roles_ability_check = true # we check the roles on assigning them

    self.roles = if self.roles.blank?
      []
    else
      site.available_user_roles_ary.select { |role_to_check| roles.include?(role_to_check.to_s) }
    end

    @disabled_roles_ability_check = false
  end

  def to_s
    "#{user.email} - #{site.domain} - #{roles}"
  end

  def locked=(bool)
    proper_bool = case bool
                  when String
                    bool != "0"
                  else
                    bool
    end

    return if proper_bool == locked?

    self.locked_at = proper_bool ? Time.current : nil
  end

  def locked?
    locked_at.present?
  end

  def locked
    locked?
  end
end

# == Schema Information
#
# Table name: folio_site_user_links
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  site_id    :bigint(8)        not null
#  roles      :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  locked_at  :datetime
#
# Indexes
#
#  index_folio_site_user_links_on_site_id  (site_id)
#  index_folio_site_user_links_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (site_id => folio_sites.id)
#  fk_rails_...  (user_id => folio_users.id)
#
