# frozen_string_literal: true

# If You add custom rules here, make sure to also add them to `object.currently_available_actions` method!
Folio::Ability.class_eval do
  def ability_rules
    folio_rules
    sidekiq_rules
    dummy_rules
  end

  def dummy_rules
    dummy_blog_rules
    dummy_test_rules if Rails.env.test?
  end

  def dummy_blog_rules
    return unless defined?(Dummy::Blog)

    if user.superadmin? || user.has_any_roles?(site:, roles: [:administrator, :manager])
      can :do_anything, Dummy::Blog::Article, { site: }
      can :do_anything, Dummy::Blog::Author, { site: }
      can :do_anything, Dummy::Blog::Topic, { site: }
    end
  end

  def dummy_test_rules
    # for ability scopes testing
    if user.has_any_roles?(site:, roles: [:manager])
      cannot :read, Folio::Lead, { site:, email: "manager_cant@see.me" }
      cannot :update, Folio::Lead, { site:, email: "manager_can_read_but_not_update@see.me" }
    end
  end
end
