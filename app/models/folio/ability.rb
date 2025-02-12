# frozen_string_literal: true

class Folio::Ability
  include CanCan::Ability
  attr_reader :user, :site

  def initialize(user, site = nil)
    return if user.nil?

    @user = user
    @site = site

    alias_action :manage, to: :do_anything
    alias_action :index, :show, :new, :create, :edit, :update, :destroy, :set_positions, :create_defaults, :new_clone, to: :crud

    ability_rules
  end

  # override to extend
  def ability_rules
    folio_rules
    sidekiq_rules
  end

  def sidekiq_rules
    if user.superadmin?
      can :do_anything, :sidekiq
    end
  end

  def folio_rules
    can [:stop_impersonating], Folio::User # anyone must be able to stop impersonating

    if user.superadmin?
      console_common_admin_rules
      can :do_anything, Folio::User
      can :impersonate, Folio::User
      can :set_superadmin, Folio::User
      cannot [:create, :new, :destroy], Folio::Site

      can :do_anything, Folio::PrivateAttachment
      can :do_anything, Folio::ConsoleNote

      can :set_administrator, Folio::Site
      can :set_manager, Folio::Site

      return
    end

    if user.has_any_roles?(site:, roles: [:administrator, :manager])
      console_common_admin_rules

      if user.has_role?(site:, role: :administrator)
        # TODO: should it be `can :do_anything, Folio::User, { auth_site: site, superadmin: false }`?`
        can :do_anything, Folio::User, { site_user_links: { site: }, superadmin: false }
        can :read_administrators, Folio::Site
        can :set_administrator, Folio::Site
        can :set_manager, Folio::Site

      elsif user.has_role?(site:, role: :manager)

        # next do not work, because in the end it tries to do `[x,y,z].include?([x,y]) => false`
        # non_admin_roles = site.available_user_roles_ary - ["administrator"]
        # can :do_anything, Folio::User, site_user_links: { site: , roles: non_admin_roles } do |user|

        can :do_anything, Folio::User, Folio::User.where(superadmin: false).without_site_roles(site:, roles: [:administrator]) do |user|
          !user.has_role?(site:, role: :administrator) && !user.superadmin?
        end
        can :set_manager, Folio::Site
      end

      cannot :impersonate, Folio::User # `can :do_anything` enabled it, so we must deny it here
      cannot :set_superadmin, Folio::User
      cannot :change_auth_site, Folio::User
      cannot :new_clone, :all unless Rails.application.config.folio_console_clonable_enabled
    end
  end
  alias_method :folio_console_rules, :folio_rules

  def console_common_admin_rules
    can :access_console, site
    can :multisearch_console, site
    can :display_ui, site
    can [:new], Folio::User # new user do not belong to site yet

    can :do_anything, Folio::SiteUserLink, { site: }
    can :do_anything, Folio::File, { site: Rails.application.config.folio_shared_files_between_sites ? [Folio::Current.main_site, site] : site }
    can :do_anything, Folio::Page, { site: }
    can :do_anything, Folio::Menu, { site: }
    can :do_anything, Folio::Lead, { site: }
    can :do_anything, Folio::NewsletterSubscription, { site: }
    can :do_anything, Folio::EmailTemplate, { site: }
    can :do_anything, Folio::AttributeType, { site: }
    can :do_anything, Folio::ContentTemplate, { site: }
    # can :do_anything, Folio::ConsoleNote, target: { site: } cannot be used, because it is polymorphic

    can [:read, :update], Folio::Site, { id: site.id }
    can :read_managers, Folio::User
  end
end
