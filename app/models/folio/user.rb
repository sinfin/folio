# frozen_string_literal: true

class Folio::User < Folio::ApplicationRecord
  include Folio::Filterable

  # used to validate before inviting from console in /console/users/new
  attribute :skip_password_validation, :boolean, default: false

  selected_device_modules = %i[
    database_authenticatable
    registerable
    recoverable
    rememberable
    trackable
    validatable
    invitable
  ]
  selected_device_modules << :confirmable if Rails.application.config.folio_users_confirmable
  selected_device_modules << :omniauthable if Rails.application.config.folio_users_omniauth_providers.present?

  devise(*selected_device_modules,
         omniauth_providers: Rails.application.config.folio_users_omniauth_providers)

  pg_search_scope :by_query,
                  against: [:email],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  scope :ordered, -> { order(id: :desc) }

  validates :first_name, :last_name,
            presence: true,
            if: :validate_first_name_and_last_name?

  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def to_label
    full_name
  end

  def to_console_label
    if (first_name.present? || last_name.present?) && email.present?
      "#{full_name} <#{email}>"
    else
      to_label
    end
  end

  def remember_me
    super.nil? ? "1" : super
  end

  private
    def validate_first_name_and_last_name?
      true
    end

    def password_required?
      if skip_password_validation?
        false
      else
        super
      end
    end
end

# == Schema Information
#
# Table name: folio_users
#
#  id                     :bigint(8)        not null, primary key
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  first_name             :string
#  last_name              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :bigint(8)
#  invitations_count      :integer          default(0)
#
# Indexes
#
#  index_folio_users_on_confirmation_token                 (confirmation_token) UNIQUE
#  index_folio_users_on_email                              (email)
#  index_folio_users_on_invitation_token                   (invitation_token) UNIQUE
#  index_folio_users_on_invited_by_id                      (invited_by_id)
#  index_folio_users_on_invited_by_type_and_invited_by_id  (invited_by_type,invited_by_id)
#  index_folio_users_on_reset_password_token               (reset_password_token) UNIQUE
#
