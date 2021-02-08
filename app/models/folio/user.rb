# frozen_string_literal: true

class Folio::User < Folio::ApplicationRecord
  include Folio::Filterable

  selected_device_modules = %i[
    database_authenticatable
    registerable
    recoverable
    rememberable
    trackable
    validatable
  ]
  selected_device_modules << :confirmable if Rails.application.config.folio_users_confirmable

  devise(*selected_device_modules)

  pg_search_scope :by_query,
                  against: [:email],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  scope :ordered, -> { order(id: :desc) }

  def to_label
    email
  end
end

# == Schema Information
#
# Table name: folio_users
#
#  id                     :bigint(8)        not null, primary key
#  email                  :string           default(""), not null
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
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_folio_users_on_confirmation_token                 (confirmation_token) UNIQUE
#  index_folio_users_on_email                              (email) UNIQUE
#  index_folio_users_on_reset_password_token               (reset_password_token) UNIQUE
#
