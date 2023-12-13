# frozen_string_literal: true

class Dummy::Ability
  include CanCan::Ability

  # rules here will override or extend rules from Folio::Ability
  def initialize(user, additional: {})
  end
end
