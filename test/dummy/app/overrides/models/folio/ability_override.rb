# frozen_string_literal: true

# If You add rules here, make sure to also add them to `object.currently_available_actions` method!
Folio::Ability.class_eval do
  def ability_rules
    folio_rules
    sidekiq_rules
    app_rules
  end

  def app_rules
    if user.superadmin?
      can :do_anything, :all # this is kinda overkill it touches console and non-console stuff
    end
  end
end
