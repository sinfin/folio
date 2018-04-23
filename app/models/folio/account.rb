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

    # Scopes
    default_scope { order(created_at: :desc) }

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

    def remember_me
      super.nil? ? '1' : super
    end

    alias :to_label :full_name
    alias :title :full_name

    def active_for_authentication?
      # remember to call the super
      # then put our own check to determine "active" state using
      # our own "is_active" column
      super && self.is_active?
    end
  end
end

# == Schema Information
#
# Table name: folio_accounts
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  first_name             :string
#  last_name              :string
#  role                   :string
#  is_active              :boolean          default(TRUE)
#
# Indexes
#
#  index_folio_accounts_on_email                 (email) UNIQUE
#  index_folio_accounts_on_reset_password_token  (reset_password_token) UNIQUE
#
