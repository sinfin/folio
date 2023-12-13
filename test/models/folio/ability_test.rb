# frozen_string_literal: true

require "test_helper"

class Folio::AbilityTest < ActiveSupport::TestCase
  attr_reader :ability, :site, :site2

  setup do
    @site = Folio.main_site || create(:folio_site)
    @site2 = create(:folio_site)
  end

  test "superadmin" do
    user = create_user(superadmin: true)

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([:manage])
    can_do_with_admins([:manage], site:)
    can_do_with_admins([:manage], site: site2)
    can_do_with_managers([:manage], site:)
    can_do_with_managers([:manage], site: site2)
    can_access_in_console([:everything], site: nil)
    can_access_in_console([:everything], site:)
    can_access_in_console([:everything], site: site2)
  end

  test "administrator" do
    user = create_user(roles: { site => [:administrator] })

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([])
    can_do_with_admins([:manage], site:)
    can_do_with_admins([], site: site2)
    can_do_with_managers([:manage], site:)
    can_do_with_managers([], site: site2)
    can_access_in_console([:everything], site: nil)
    can_access_in_console([:everything], site:)
    can_access_in_console([], site: site2)
  end

  test "manager" do
    user = create_user(roles: { site => [:manager] })

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([])
    can_do_with_admins([], site:)
    can_do_with_managers([:manage], site:)
    can_access_in_console([:everything])
  end

  test "so called user" do
    # user = create(:folio_user)
    # user.set_roles_for(site:, roles: [])

    # @ability = Folio::Ability.new(user)

    # can_do_with_superadmins([])
    # can_do_with_admins([], site:)
    # can_do_with_managers([], site:)
    # can_access_in_console([])
  end

  test "no user of any kind" do
    # view homepage, sign_in, sign_up
  end

  private
    READ_ACTIONS = [ :index, :show ]
    CREATE_ACTIONS = [ :new, :create ]
    UPDATE_ACTIONS = [ :edit, :update ]
    DESTROY_ACTIONS = [ :destroy ]
    CRUD_ACTIONS = CREATE_ACTIONS + READ_ACTIONS + UPDATE_ACTIONS + DESTROY_ACTIONS

    ALL_KNOWN_ACTIONS_ON = {
      superadmins: CRUD_ACTIONS + [:index_superadmins, :create_superadmins],
      admins: CRUD_ACTIONS + [:index_admins, :create_admins],
      managers: CRUD_ACTIONS + [:index_managers, :create_managers],
    }

    def can_do_with_superadmins(actions)
      allowed_actions = expand_actions(actions)
      allowed_actions << :index_superadmins if allowed_actions.include?(:index)
      allowed_actions << :create_superadmins if allowed_actions.include?(:new)
      allowed_actions << :create_superadmins if allowed_actions.include?(:create)

      superadmin = create_user(superadmin: true, email: "superadmin@folio.com")

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:superadmins]),
                                   object: superadmin)
    end

    def can_do_with_admins(actions, site:)
      allowed_actions = expand_actions(actions)
      allowed_actions << :index_admins if allowed_actions.include?(:index)
      allowed_actions << :create_admins if allowed_actions.include?(:new)
      allowed_actions << :create_admins if allowed_actions.include?(:create)

      admin = create_user(email: "administrator@#{site.domain}", roles: { site => [:administrator] })

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:admins]),
                                   object: admin,
                                   site:)
    end

    def can_do_with_managers(actions, site:)
      allowed_actions = expand_actions(actions)
      allowed_actions << :index_managers if allowed_actions.include?(:index)
      allowed_actions << :create_managers if allowed_actions.include?(:new)
      allowed_actions << :create_managers if allowed_actions.include?(:create)

      manager = create_user(email: "manager@#{site.domain}", roles: { site => [:manager] })

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:managers]),
                                                   object: manager,
                                                   site:)
    end

    def can_access_in_console(actions, site: nil)
    end

    def build_checklist(allowed_actions, all_known_actions)
      if (diff = allowed_actions - all_known_actions).present?
        raise "allowed_actions includes actions `#{diff}` which is not covered in all_known_actions"
      end

      all_known_actions.index_with do |action|
        allowed_actions.include?(action)
      end
    end

    def expand_actions(actions)
      actions += [:edit, :update] if actions.delete(:edit)
      actions += [:index, :show] if actions.delete(:read)
      actions += [:index, :show, :new, :create, :edit, :update, :destroy] if actions.delete(:manage)

      actions.uniq.sort
    end

    def assert_user_is_restricted_to(checklist, object: nil, site: nil)
      checklist.each do |action, allowed|
        if allowed
          assert ability.can?(action, object), "(#{user_to_str(site)})\n should be able on site `#{site&.domain}` to do :#{action}\n on object #{object.to_json}"
        else
          assert_not ability.can?(action, object), "(#{user_to_str(site)})\n should NOT be able on site `#{site&.domain}` to do :#{action}\n on object #{object.to_json}"
        end
      end
    end

    def user_to_str(site)
      user = ability.user
      roles = site.present? ? user.roles_for(site:) : []
      "superadmin: #{user.superadmin?}, roles: #{roles}"
    end

    # hack to remove creating newsletter_subscription after user creation
    def create_user(attrs)
      roles_for_sites = attrs.delete(:roles) || {}
      user = build(:folio_user, **attrs)
      def user.newsletter_subscriptions_enabled?
        false
      end
      roles_for_sites.each_pair do |site, roles|
        user.set_roles_for(site:, roles:)
      end

      user.save!
      user
    end
end
