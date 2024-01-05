# frozen_string_literal: true

class Folio::Console::SiteUserLinks::FieldsComponent < Folio::Console::ApplicationComponent
  def initialize(f:)
    @f = f
    @user = @f.object
  end

  def allowed_sites_links
    Folio::Site.order(domain: :asc).filter_map do |site|
      next unless current_user.can_now?(:manage, Folio::User, site:)

      link = @user.site_user_links.joins(:site).detect { |l| l.site == site }

      if link.blank?
        roles = (site == current_site && @user.new_record?) ? [] : nil
        link = @user.site_user_links.build(site:, roles:)
      end

      link
    end
  end

  def roles_for(site_link)
    @user.class.roles_for_select(site: site_link.site)
  end

  def id_for(site_link, role_key)
    "user_site_user_links_attributes_#{site_link.id}_roles_#{role_key}"
  end

  def data
    stimulus_controller("f-c-site-user-links-fields",
                        action: { change: "onAnyChange" })
  end
end
