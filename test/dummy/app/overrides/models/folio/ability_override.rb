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
  end

  def dummy_blog_rules
    return unless defined?(Dummy::Blog)

    if user.superadmin? || user.has_any_roles?(site:, roles: [:administrator, :manager])
      can :do_anything, Dummy::Blog::Article, { site: }
      can :do_anything, Dummy::Blog::Author, { site: }
      can :do_anything, Dummy::Blog::Topic, { site: }
    end
  end
end
