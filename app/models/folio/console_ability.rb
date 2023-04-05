# frozen_string_literal: true

class Folio::ConsoleAbility
  include CanCan::Ability

  def initialize(account)
    return if account.nil?

    if account.is_a?(Folio::Account)
      account_rules(account)
    elsif Rails.application.config.folio_allow_users_to_console && account.is_a?(Folio::User)
      user_rules(account)
    end

    Rails.application.config.folio_console_ability_lambda.call(self, account)
  end

  def account_rules(account)
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
  end

  def user_rules(user)
    fail "Override this in your app/overrides/models/folio/console_ability_override.rb"
  end
end
