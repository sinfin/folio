# frozen_string_literal: true

class Folio::SiteUserLink < Folio::ApplicationRecord
  belongs_to :user, class_name: "Folio::User",
                    inverse_of: :site_user_links
  belongs_to :site, class_name: "Folio::Site",
                    inverse_of: :site_user_links

  validate :validate_roles_from_site

  def validate_roles_from_site
    forbidden_roles = (roles.to_a.collect(&:to_s) - site.available_user_roles.to_a)
    if forbidden_roles.present?
      errors.add(:roles, :not_available_for_site, site: site.domain, roles: forbidden_roles.to_s)
    else
      normalize_site_roles
    end
  end

  # keep defined order and allow only known roles
  def normalize_site_roles
    self.roles = if self.roles.blank?
      []
    else
      site.available_user_roles.select { |role_to_check| roles.include?(role_to_check.to_s) }
    end
 end
end

# == Schema Information
#
# Table name: folio_site_user_links
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  site_id    :bigint(8)        not null
#  roles      :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
