# frozen_string_literal: true

class ConsoleAbility
  include CanCan::Ability

  def initialize(account)
    account ||= Folio::Account.new

    case account.role
    when 'manager'
      can :manage, :all
      cannot :manage, Folio::Account, role: 'superuser'
    when 'superuser'
      can :manage, :all
    end
  end
end
