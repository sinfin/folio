# frozen_string_literal: true

# If You add custom rules here, make sure to also add them to `object.currently_available_actions` method!
Folio::Ability.class_eval do
  def ability_rules
    folio_rules
    sidekiq_rules
    dummy_rules
  end

  def dummy_rules
  end
end
