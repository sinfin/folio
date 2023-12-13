# frozen_string_literal: true

class Folio::Ability
  include CanCan::Ability
  attr_reader :user, :site

  def initialize(user, site = nil)
    return if user.nil?

    @user = user
    @site = site

    folio_console_rules
  end


  def folio_console_rules
    if user.superadmin?
      can :manage, :all
      return
    end

    if user.has_any_roles?(site:, roles: [:administrator, :manager])
      can :manage, :all
      cannot :manage, :sidekiq
      cannot :manage, Folio::User

      if site.present?
        if user.has_role?(site:, role: :administrator)
          can :manage, Folio::User, site_user_links: { site: }
        elsif user.has_role?(site:, role: :manager)
          # next do not work, beacouse in the end it tries to do `[x,y,z].include?([x,y]) => false`
          # non_admin_roles = site.available_user_roles - ["administrator"]
          # can :manage, Folio::User, site_user_links: { site: , roles: non_admin_roles } do |user|

          can :manage, Folio::User, Folio::User.without_site_roles(site:, roles: [:administrator]) do |user|
            !user.has_role?(site:, role: :administrator) && !user.superadmin?
          end
        end
      end
    end
  end
end
