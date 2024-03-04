# frozen_string_literal: true

require "test_helper"

class Folio::AbilityTest < ActiveSupport::TestCase
  attr_reader :ability, :site1, :site2, :tested_site

  MAXIMUM_ACTIONS = { general: [:access_console],
                      superadmins: [:manage],
                      administrators: [:manage],
                      managers: [:manage],
                      users: [:manage, :impersonate, :stop_impersonating],
                      images: [:manage],
                      videos: [:manage],
                      audios: [:manage],
                      documents: [:manage],
                      # blog_articles: [:manage],
                      # blog_topics: [:manage],
                      pages: [:manage],
                      menus: [:manage],
                      leads: [:manage],
                      newsletter_subscriptions: [:manage],
                      email_templates: [:manage],
                      sites: [:read, :modify] }.freeze # C+U are done by rails console (?)

  setup do
    @site1 = Folio::Site.first || create(:folio_site, domain: "first.com")
    @site2 = Folio::Site.second || create(:folio_site, domain: "second.com")
  end

  test "superadmin on site1" do
    user = create_user(superadmin: true)
    @tested_site = site1
    allowed_actions = MAXIMUM_ACTIONS

    check_abilities(user, allowed_actions)
  end

  test "superadmin on site2" do
    user = create_user(superadmin: true)
    @tested_site = site2
    allowed_actions = MAXIMUM_ACTIONS

    check_abilities(user, allowed_actions)
  end

  test "administrator on his site" do
    user = create_user(roles: { site1 => [:administrator] })
    @tested_site = site1
    allowed_actions = MAXIMUM_ACTIONS.merge({ superadmins: [:new],
                                              users: [:manage, :stop_impersonating],
                                              sites: [:read, :modify] })

    check_abilities(user, allowed_actions)
  end

  test "administrator on other site" do
    user = create_user(roles: { site1 => [:administrator] })
    @tested_site = site2
    allowed_actions = { users: [:stop_impersonating] }

    check_abilities(user, allowed_actions)
  end

  test "manager on his site" do
    user = create_user(roles: { site1 => [:manager] })
    @tested_site = site1
    allowed_actions = MAXIMUM_ACTIONS.merge({ superadmins: [:new],
                                              administrators: [:new],
                                              users: [:manage, :stop_impersonating],
                                              sites: [:read, :modify] })

    check_abilities(user, allowed_actions)
  end

  test "manager on other site" do
    user = create_user(roles: { site1 => [:manager] })
    @tested_site = site2
    allowed_actions = { users: [:stop_impersonating] }

    check_abilities(user, allowed_actions)
  end

  test "so called user on his site" do
    user = create_user(roles: { site1 => [] })
    @tested_site = site1
    allowed_actions = { users: [:stop_impersonating] }

    check_abilities(user, allowed_actions)
  end

  test "not yet user on his site" do
    user = create_user(email: "notyetuser@#{site1.domain}")
    @tested_site = site1
    allowed_actions = { users: [:stop_impersonating] }

    check_abilities(user, allowed_actions)
  end

  test "no user of any kind" do
    # view homepage, sign_in, sign_up
    user = nil
    @tested_site = site1
    allowed_actions = {}

    check_abilities(user, allowed_actions)
  end

  private
    def check_abilities(user, allowed_actions)
      @ability = Folio::Ability.new(user, tested_site)

      MAXIMUM_ACTIONS.each_pair do |object_group, all_actions|
        # puts("checking #{object_group} on #{tested_site.domain} => #{MAXIMUM_ACTIONS}")

        checklist = build_checklist(allowed_actions[object_group], all_actions)
        tested_object = get_tested_object(object_group)

        assert_user_is_restricted_to(checklist, object: tested_object, site: tested_site)
      end
    end

    def get_tested_object(object_group)
      case object_group
      when :general
        tested_site
      when :superadmins
        create_user(superadmin: true, email: "superadmin@folio.com")
      when :administrators
        create_user(email: "administrator@#{tested_site.domain}", roles: { tested_site => [:administrator] })
      when :managers
        create_user(email: "manager@#{tested_site.domain}", roles: { tested_site => [:manager] })
      when :users
        create_user(email: "user@#{tested_site.domain}", roles: { tested_site => [] })
      when :images
        create(:folio_file_image, site: tested_site)
      when :videos
        create(:folio_file_video, site: tested_site)
      when :audios
        create(:folio_file_audio, site: tested_site)
      when :documents
        create(:folio_file_document, site: tested_site)
      when :blog_articles
        create(:dummy_blog_article, site: tested_site)
      when :blog_topics
        create(:dummy_blog_topic, site: tested_site)
      when :pages
        create(:folio_page, site: tested_site)
      when :menus
        create(:folio_menu, type: Dummy::Menu::Header, site: tested_site)
      when :leads
        create(:folio_lead, site: tested_site)
      when :newsletter_subscriptions
        create(:folio_newsletter_subscription, site: tested_site)
      when :email_templates
        create(:folio_email_template, site: tested_site)
      when :sites
        tested_site
      else
        raise "unknown object for object_group `#{object_group}`"
      end
    end

    def build_checklist(allowed_actions, all_known_actions)
      expanded_allowed_actions = expand_actions(allowed_actions)
      expanded_all_known_actions = expand_actions(all_known_actions)

      if (diff = expanded_allowed_actions - expanded_all_known_actions).present?
        raise "allowed_actions includes actions `#{diff}` which is not covered in all_known_actions"
      end

      expanded_all_known_actions.index_with do |action|
        expanded_allowed_actions.include?(action)
      end
    end

    def expand_actions(actions)
      expanded_actions = actions.blank? ? [] : actions.dup
      expanded_actions += [:show, :edit, :update] if expanded_actions.delete(:modify)
      expanded_actions += [:index, :show] if expanded_actions.delete(:read)
      expanded_actions += [:index, :show, :new, :create, :edit, :update, :destroy] if expanded_actions.delete(:manage)

      expanded_actions.uniq.sort
    end

    def assert_user_is_restricted_to(checklist, object: nil, site: nil)
      checklist.each do |action, allowed|
        obj = action == :new ? object.class : object

        if allowed
          assert ability.can?(action, obj), "(#{user_to_str(site)})\n should be able on site `#{site&.domain}` to do :#{action}\n on <#{object.class.name}> #{object.to_json}"
        else
          assert_not ability.can?(action, obj), "(#{user_to_str(site)})\n should NOT be able on site `#{site&.domain}` to do :#{action}\n on <#{object.class.name}> #{object.to_json}"
        end
      end
    end

    def user_to_str(site)
      user = ability.user
      return "no user" if user.nil?

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
