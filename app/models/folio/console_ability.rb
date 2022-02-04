# frozen_string_literal: true

class Folio::ConsoleAbility
  include CanCan::Ability

  def initialize(account)
    account ||= Folio::Account.new

    case account.role
    when "manager"
      can :manage, :all
      cannot :manage, :sidekiq
      cannot :manage, Folio::Account, role: "superuser"
      cannot :manage, Folio::Account, role: "administrator"
    when "administrator"
      can :manage, :all
      cannot :manage, :sidekiq
    when "superuser"
      can :manage, :all
    end
  end
end
