# frozen_string_literal: true

class Folio::ConsoleAbility
  include CanCan::Ability

  def initialize(account)
    account ||= Folio::Account.new

    if account.roles.include?("superuser")
      can :manage, :all
    elsif account.roles.include?("administrator")
      can :manage, :all
      cannot :manage, :sidekiq
    elsif account.roles.include?("manager")
      can :manage, :all
      cannot :manage, :sidekiq
      cannot :manage, Folio::Account, role: "superuser"
      cannot :manage, Folio::Account, role: "administrator"
    end

    Rails.application.config.folio_console_ability_lambda.call(self, account)
  end
end
