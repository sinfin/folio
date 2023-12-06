# frozen_string_literal: true

class Folio::Console::Users::RolesFormCell < Folio::ConsoleCell
  def user_form
    model
  end

  def user
    user_form.object
  end

  def all_sites_links
    @all_sites_links ||= Folio::Site.all.order(domain: :asc).map do |site|
      link = user.site_user_links.joins(:site).detect { |l| l.site == site }
      link ||= user.site_user_links.build(site:, roles: nil)
      link
    end
  end
end
