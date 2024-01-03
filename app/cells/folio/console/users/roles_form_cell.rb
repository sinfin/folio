# frozen_string_literal: true

class Folio::Console::Users::RolesFormCell < Folio::ConsoleCell
  def user_form
    model
  end

  def user
    user_form.object
  end

  def allowed_sites_links
    @all_sites_links ||= Folio::Site.all.order(domain: :asc).filter_map do |site|
      next unless current_user.can_now?(:manage, Folio::User, site:)

      link = user.site_user_links.joins(:site).detect { |l| l.site == site }
      if link.blank?
        roles = (site == current_site && user.new_record?) ? [] : nil
        link = user.site_user_links.build(site:, roles:)
      end
      link
    end
  end
end
