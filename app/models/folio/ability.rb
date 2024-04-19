# frozen_string_literal: true

class Folio::Ability
  include CanCan::Ability
  attr_reader :user, :site

  def initialize(user, site = nil)
    return if user.nil?

    @user = user
    @site = site

    alias_action :manage, to: :do_anything
    alias_action :index, :show, :new, :create, :edit, :update, :destroy, :set_positions, :create_defaults, to: :crud

    ability_rules
  end

  # override to extend
  def ability_rules
    folio_console_rules
  end

  def folio_console_rules
    if user.superadmin?
      can :do_anything, :all
      can :access_console, Folio::Site
      can :impersonate, Folio::User
      can :set_superadmin, Folio::User
      can :multisearch_console, Folio::Site
      cannot [:create, :new, :destroy], Folio::Site
      return
    end

    can [:stop_impersonating], Folio::User # anyone must be able to stop impersonating

    if user.has_any_roles?(site:, roles: [:administrator, :manager])
      can :access_console, site
      can :multisearch_console, site
      can :display_ui, site
      can [:new], Folio::User # new user do not belong to site yet
      # can :display_miniprofiler, site


      if user.has_role?(site:, role: :administrator)
        can :do_anything, Folio::User, site_user_links: { site: }
        can :read_administrators, Folio::User
        can :read_managers, Folio::User
      elsif user.has_role?(site:, role: :manager)
        can :read_managers, Folio::User
        # next do not work, because in the end it tries to do `[x,y,z].include?([x,y]) => false`
        # non_admin_roles = site.available_user_roles_ary - ["administrator"]
        # can :do_anything, Folio::User, site_user_links: { site: , roles: non_admin_roles } do |user|

        can :do_anything, Folio::User, Folio::User.without_site_roles(site:, roles: [:administrator]) do |user|
          !user.has_role?(site:, role: :administrator) && !user.superadmin?
        end
        cannot :set_administrator, Folio::User
      end

      can :do_anything, Folio::File, { site: }
      can :do_anything, Folio::Page, { site: }
      can :do_anything, Folio::Menu, { site: }
      can :do_anything, Folio::Lead, { site: }
      can :do_anything, Folio::NewsletterSubscription, { site: }
      can :do_anything, Folio::EmailTemplate, { site: }
      can [:read, :update], Folio::Site, { id: site.id }

      cannot :impersonate, Folio::User # `can :do_anything` enabled it, so we must deny it here
      cannot :set_superadmin, Folio::User
    end
  end
end
