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
    non_console_rules
  end

  def non_console_rules
    unless Rails.env.test?
      puts("Override Folio::Ability.non_console_rules method to define rules for non-console actions.")
      puts("Even superadmin should be forced to use impersonation for non-admin usage.")
      puts("Or overide Folio::Ability.ability_rules method to not call `non_console_rulles`.")
    end

    if user.superadmin?
      can :do_anything, :all # this is kinda overkill
    end
  end

  def folio_console_rules
    can [:stop_impersonating], Folio::User # anyone must be able to stop impersonating

    if user.superadmin?
      console_common_admin_rules
      can :do_anything, Folio::User
      can :impersonate, Folio::User
      can :set_superadmin, Folio::User
      cannot [:create, :new, :destroy], Folio::Site

      can :do_anything, Folio::PrivateAttachment
      can :do_anything, Folio::ConsoleNote
      return
    end

    if user.has_any_roles?(site:, roles: [:administrator, :manager])
      console_common_admin_rules

      if user.has_role?(site:, role: :administrator)
        can :do_anything, Folio::User, site_user_links: { site: }
        can :read_administrators, Folio::User
      elsif user.has_role?(site:, role: :manager)

        # next do not work, because in the end it tries to do `[x,y,z].include?([x,y]) => false`
        # non_admin_roles = site.available_user_roles_ary - ["administrator"]
        # can :do_anything, Folio::User, site_user_links: { site: , roles: non_admin_roles } do |user|

        can :do_anything, Folio::User, Folio::User.without_site_roles(site:, roles: [:administrator]) do |user|
          !user.has_role?(site:, role: :administrator) && !user.superadmin?
        end
        cannot :set_administrator, Folio::User
      end
      cannot :impersonate, Folio::User # `can :do_anything` enabled it, so we must deny it here
      cannot :set_superadmin, Folio::User
    end
  end
  def console_common_admin_rules
    can :access_console, site
    can :multisearch_console, site
    can :display_ui, site
    can [:new], Folio::User # new user do not belong to site yet

    can :do_anything, Folio::SiteUserLink, { site: }
    can :do_anything, Folio::File, { site: Rails.application.config.folio_shared_files_between_sites ? [Folio.main_site, site] : site }
    can :do_anything, Folio::Page, { site: }
    can :do_anything, Folio::Menu, { site: }
    can :do_anything, Folio::Lead, { site: }
    can :do_anything, Folio::NewsletterSubscription, { site: }
    can :do_anything, Folio::EmailTemplate, { site: }
    # can :do_anything, Folio::ConsoleNote, target: { site: } cannot be used, because it is polymorphic

    can [:read, :update], Folio::Site, { id: site.id }
    can :read_managers, Folio::User
  end
end
