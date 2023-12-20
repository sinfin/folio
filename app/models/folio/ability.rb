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
      can :access_console, Folio::Site
      cannot [:create, :new, :destroy], Folio::Site
      return
    end

    if user.has_any_roles?(site:, roles: [:administrator, :manager])
      can :access_console, site
      can :display_ui, site
      # can :display_miniprofiler, site

      if user.has_role?(site:, role: :administrator)
        can :manage, Folio::User, site_user_links: { site: }
        can :read_administrators, Folio::User
        can :read_managers, Folio::User
      elsif user.has_role?(site:, role: :manager)
        can :read_managers, Folio::User
        # next do not work, beacouse in the end it tries to do `[x,y,z].include?([x,y]) => false`
        # non_admin_roles = site.available_user_roles - ["administrator"]
        # can :manage, Folio::User, site_user_links: { site: , roles: non_admin_roles } do |user|

        can :manage, Folio::User, Folio::User.without_site_roles(site:, roles: [:administrator]) do |user|
          !user.has_role?(site:, role: :administrator) && !user.superadmin?
        end
      end

      can :manage, Folio::File, { site: }
      can :manage, Folio::Page, { site: }
      can :manage, Folio::Menu, { site: }
      can :manage, Folio::Lead, { site: }
      can :manage, Folio::NewsletterSubscription, { site: }
      can :manage, Folio::EmailTemplate, { site: }
      can [:read, :update], Folio::Site, { id: site.id }
    end
  end
end
