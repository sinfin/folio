# frozen_string_literal: true

module Folio
  class Account < ApplicationRecord
    ROLES = %w( superuser manager ).freeze

    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :recoverable, :rememberable,
           :trackable, :validatable

    validates :role, inclusion: ROLES
    validates :first_name, :last_name, presence: true

    scope :by_query, -> (q) {
      if q.present?
        args = ["%#{q}%"] * 2
        where('first_name ILIKE ? OR last_name ILIKE ?', *args)
      else
        where(nil)
      end
    }

    scope :by_is_active, -> (b) {
      unless b.nil?
        where(is_active: b)
      else
        where(is_active: true)
      end
    }

    def superuser?
      role == 'superuser'
    end

    def manager?
      role == 'manager'
    end

    def full_name
      if first_name || last_name
        "#{first_name} #{last_name}"
      else
        email
      end
    end

    alias :to_label :full_name
    alias :title :full_name

    def active_for_authentication?
      #remember to call the super
      #then put our own check to determine "active" state using
      #our own "is_active" column
      super && self.is_active?
    end
  end
end
