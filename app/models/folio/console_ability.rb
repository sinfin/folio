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

      cannot :manage, Folio::Account
      can :index, Folio::Account
      can :manage, Folio::Account, Folio::Account.without_role("superuser") do |account|
        !account.has_role?("superuser")
      end
    elsif account.roles.include?("manager")
      can :manage, :all
      cannot :manage, :sidekiq

      cannot :manage, Folio::Account
      can :index, Folio::Account
      can :manage, Folio::Account, Folio::Account.without_roles(%w[superuser administrator]) do |account|
        !account.has_any_roles?(%w[superuser administrator])
      end
    end

    Rails.application.config.folio_console_ability_lambda.call(self, account)
  end
end
