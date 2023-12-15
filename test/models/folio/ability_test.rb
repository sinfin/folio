# frozen_string_literal: true

require "test_helper"

class Folio::AbilityTest < ActiveSupport::TestCase
  attr_reader :ability, :site, :site2

  setup do
    @site = Folio::Site.first || create(:folio_site, domain: "first.com")
    @site2 = Folio::Site.second || create(:folio_site, domain: "second.com")
  end

  test "superadmin" do
    user = create_user(superadmin: true)

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([:manage])
    can_do_with_admins([:manage], site:)
    can_do_with_admins([:manage], site: site2)
    can_do_with_managers([:manage], site:)
    can_do_with_managers([:manage], site: site2)

    assert ability.can?(:access_console, site:)
    assert ability.can?(:access_console, site: site2)
    can_do_with_base_models_in_console([:manage], site:)
    can_do_with_base_models_in_console([:manage], site: site2)

    can_do_with_sites([:read, :modify], site:)
    can_do_with_sites([:read, :modify], site: site2)
  end

  test "administrator" do
    user = create_user(roles: { site => [:administrator] })

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([])
    can_do_with_admins([:manage], site:)
    can_do_with_admins([], site: site2)
    can_do_with_managers([:manage], site:)
    can_do_with_managers([], site: site2)

    assert ability.can?(:access_console, site:)
    assert_not ability.can?(:access_console, site: site2)
    can_do_with_base_models_in_console([:manage], site:)
    can_do_with_base_models_in_console([], site: site2)

    can_do_with_sites([:read, :modify], site:)
    can_do_with_sites([], site: site2)
  end


  test "manager" do
    user = create_user(roles: { site => [:manager] })

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([])
    can_do_with_admins([], site:)
    can_do_with_managers([:manage], site:)

    assert ability.can?(:access_console, site:)
    assert_not ability.can?(:access_console, site: site2)
    can_do_with_base_models_in_console([:manage], site:)
    can_do_with_base_models_in_console([], site: site2)

    can_do_with_sites([:read, :modify], site:)
    can_do_with_sites([], site: site2)
  end

  test "so called user" do
    user = create_user(roles: { site => [] })

    @ability = Folio::Ability.new(user, site)

    can_do_with_superadmins([])
    can_do_with_admins([], site:)
    can_do_with_managers([], site:)
    assert_not ability.can?(:access_console, site:)
    assert_not ability.can?(:access_console, site: site2)
  end

  test "no user of any kind" do
    # view homepage, sign_in, sign_up
    @ability = Folio::Ability.new(nil, site)
    assert_not ability.can?(:access_console, site:)
  end

  private
    READ_ACTIONS = [ :index, :show ]
    CREATE_ACTIONS = [ :new, :create ]
    UPDATE_ACTIONS = [ :edit, :update ]
    DESTROY_ACTIONS = [ :destroy ]
    CRUD_ACTIONS = CREATE_ACTIONS + READ_ACTIONS + UPDATE_ACTIONS + DESTROY_ACTIONS

    ALL_KNOWN_ACTIONS_ON = {
      superadmins: CRUD_ACTIONS, # + [:index_superadmins, :create_superadmins],
      admins: CRUD_ACTIONS, # + [:index_admins, :create_admins],
      managers: CRUD_ACTIONS, # + [:index_managers, :create_managers],
      images: CRUD_ACTIONS,
      videos: CRUD_ACTIONS,
      audios: CRUD_ACTIONS,
      documents: CRUD_ACTIONS,
      blog_articles: CRUD_ACTIONS,
      blog_topics: CRUD_ACTIONS,
      pages: CRUD_ACTIONS,
      menus: CRUD_ACTIONS,
      leads: CRUD_ACTIONS,
      newsletter_subscriptions: CRUD_ACTIONS,
      email_templates: CRUD_ACTIONS,
      sites: READ_ACTIONS + UPDATE_ACTIONS,  # C+U are done by rails console (?)
    }

    def can_do_with_superadmins(actions)
      allowed_actions = expand_actions(actions)
      # allowed_actions << :index_superadmins if allowed_actions.include?(:index)
      # allowed_actions << :create_superadmins if allowed_actions.include?(:new)
      # allowed_actions << :create_superadmins if allowed_actions.include?(:create)

      superadmin = create_user(superadmin: true, email: "superadmin@folio.com")

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:superadmins]),
                                   object: superadmin)
    end

    def can_do_with_admins(actions, site:)
      allowed_actions = expand_actions(actions)
      # allowed_actions << :index_admins if allowed_actions.include?(:index)
      # allowed_actions << :create_admins if allowed_actions.include?(:new)
      # allowed_actions << :create_admins if allowed_actions.include?(:create)

      admin = create_user(email: "administrator@#{site.domain}", roles: { site => [:administrator] })

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:admins]),
                                   object: admin,
                                   site:)
    end

    def can_do_with_managers(actions, site:)
      allowed_actions = expand_actions(actions)
      # allowed_actions << :index_managers if allowed_actions.include?(:index)
      # allowed_actions << :create_managers if allowed_actions.include?(:new)
      # allowed_actions << :create_managers if allowed_actions.include?(:create)

      manager = create_user(email: "manager@#{site.domain}", roles: { site => [:manager] })

      assert_user_is_restricted_to(build_checklist(allowed_actions, ALL_KNOWN_ACTIONS_ON[:managers]),
                                   object: manager,
                                   site:)
    end

    def can_do_with_base_models_in_console(actions, site:)
      allowed_actions = expand_actions(actions)
      can_do_with_images(allowed_actions, site:)
      can_do_with_videos(allowed_actions, site:)
      can_do_with_audios(allowed_actions, site:)
      can_do_with_documents(allowed_actions, site:)

      can_do_with_pages(allowed_actions, site:)
      can_do_with_menus(allowed_actions, site:)
      can_do_with_leads(allowed_actions, site:)
      can_do_with_newsletter_subscriptions(allowed_actions, site:)
      can_do_with_email_templates(allowed_actions, site:)
    end

    def can_do_with_images(actions, site:)
      image = create(:folio_file_image, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:images]),
                                   object: image,
                                   site:)
    end

    def can_do_with_videos(actions, site:)
      video = create(:folio_file_video, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:videos]),
                                   object: video,
                                   site:)
    end

    def can_do_with_audios(actions, site:)
      audio = create(:folio_file_audio, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:audios]),
                                   object: audio,
                                   site:)
    end

    def can_do_with_documents(actions, site:)
      document = create(:folio_file_document, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:documents]),
                                   object: document,
                                   site:)
    end

    # def can_do_with_blog_articles(actions, site:)
    #   audio = create(:folio_file_audio, site:)
    #   assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:audios]),
    #                                        object: audio,
    #                                                site:)
    # end

    # def can_do_with_sxs(actions, site:)
    #   sx = create(:folio_sx, site:)
    #   assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:sxs]),
    #                                object: sx,
    #                                site:)
    # end

    def can_do_with_pages(actions, site:)
      page = create(:folio_page, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:pages]),
                                   object: page,
                                   site:)
    end

    def can_do_with_menus(actions, site:)
      menu = create(:folio_menu, type: Dummy::Menu::Header, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:menus]),
                                   object: menu,
                                   site:)
    end

    def can_do_with_leads(actions, site:)
      lead = create(:folio_lead, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:leads]),
                                   object: lead,
                                   site:)
    end

    def can_do_with_newsletter_subscriptions(actions, site:)
      newsletter_subscription = create(:folio_newsletter_subscription, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:newsletter_subscriptions]),
                                   object: newsletter_subscription,
                                   site:)
    end

    def can_do_with_email_templates(actions, site:)
      email_template = create(:folio_email_template, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:email_templates]),
                                   object: email_template,
                                   site:)
    end

    def can_do_with_sites(actions, site:)
      assert_user_is_restricted_to(build_checklist(expand_actions(actions), ALL_KNOWN_ACTIONS_ON[:sites]),
                                   object: site,
                                   site:)
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
      actions += [:show, :edit, :update] if actions.delete(:modify)
      actions += [:index, :show] if actions.delete(:read)
      actions += [:index, :show, :new, :create, :edit, :update, :destroy] if actions.delete(:manage)

      actions.uniq.sort
    end

    def assert_user_is_restricted_to(checklist, object: nil, site: nil)
      checklist.each do |action, allowed|
        if allowed
          assert ability.can?(action, object), "(#{user_to_str(site)})\n should be able on site `#{site&.domain}` to do :#{action}\n on <#{object.class.name}> #{object.to_json}"
        else
          assert_not ability.can?(action, object), "(#{user_to_str(site)})\n should NOT be able on site `#{site&.domain}` to do :#{action}\n on <#{object.class.name}> #{object.to_json}"
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
