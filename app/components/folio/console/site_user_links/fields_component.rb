# frozen_string_literal: true

class Folio::Console::SiteUserLinks::FieldsComponent < Folio::Console::ApplicationComponent
  def initialize(f: nil, user: nil)
    @f = f
    @user = user || @f.object
  end

  def allowed_sites_links
    Folio::Site.order(domain: :asc).filter_map do |site|
      link = @user.user_link_for(site:)
      if link.blank?
        roles = (site == current_site && @user.new_record?) ? [] : nil
        link = @user.site_user_links.build(site:, roles:)
      end

      next unless current_user.can_now?(:update, link)

      link
    end
  end

  def roles_for(site_link)
    @user.class.roles_for_select(site: site_link.site).select do |role_title, role|
      current_user.can_manage_role?(role, site_link.site)
    end
  end

  def id_for(site_link, role_key)
    "user_site_user_links_attributes_#{site_link.id}_roles_#{role_key}"
  end

  def data
    if @f
      stimulus_controller("f-c-site-user-links-fields",
                          action: { change: "onAnyChange" })
    end
  end

  def status_icon(bool)
    icon = folio_icon(bool ? :check : :close, height: 12)
    content_tag(:div, icon, class: "f-c-site-user-links-fields__status-circle f-c-site-user-links-fields__status-circle--#{bool}")
  end
end
