# frozen_string_literal: true

class Folio::User < Folio::ApplicationRecord
  include Folio::Devise::DeliverLater
  include Folio::Filterable
  include Folio::HasAddresses
  include Folio::HasNewsletterSubscription

  has_sanitized_fields :email, :first_name, :last_name, :nickname

  # used to validate before inviting from console in /console/users/new
  attribute :skip_password_validation, :boolean, default: false

  selected_device_modules = %i[
    database_authenticatable
    recoverable
    rememberable
    trackable
    validatable
    invitable
  ]

  selected_device_modules << :confirmable if Rails.application.config.folio_users_confirmable
  selected_device_modules << :omniauthable if Rails.application.config.folio_users_omniauth_providers.present?

  devise_options = {
    omniauth_providers: Rails.application.config.folio_users_omniauth_providers.presence
  }.compact

  devise(*selected_device_modules, devise_options)

  pg_search_scope :by_query,
                  against: [:email, :last_name, :first_name, :nickname],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  has_many :authentications, class_name: "Folio::Omniauth::Authentication",
                             foreign_key: :folio_user_id,
                             inverse_of: :user,
                             dependent: :destroy

  scope :ordered, -> { order(id: :desc) }

  validates :first_name, :last_name,
            presence: true,
            if: :validate_first_name_and_last_name?

  validates :phone,
            phone: true,
            if: :validate_phone?

  after_invitation_accepted :update_newsletter_subscription

  before_update :update_has_generated_password

  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def to_label
    if first_name.present? || last_name.present?
      full_name
    elsif nickname.present?
      nickname
    else
      email
    end
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

  def password_required?
    if skip_password_validation? || authentications.present?
      false
    else
      !persisted? || !password.nil? || !password_confirmation.nil?
    end
  end

  def requires_subscription_confirmation?
    false
  end

  def self.csv_attribute_names
    %i[id first_name last_name nickname email phone created_at sign_in_count last_sign_in_at admin_note]
  end

  def csv_attributes(controller = nil)
    self.class.csv_attribute_names.map do |attr|
      send(attr)
    end
  end

  def self.new_from_auth(auth)
    user = self.new

    user.email = auth.email

    if auth.nickname.present?
      ary = auth.nickname.split(/\s+/, 2)
      user.first_name = ary[0]
      user.last_name = ary[1]
    end

    user.authentications << auth

    user
  end

  def self.controller_strong_params_for_create
    address_strong_params = %i[
      id
      _destroy
      name
      company_name
      address_line_1
      address_line_2
      zip
      city
      country_code
      phone
    ]

    [
      :first_name,
      :last_name,
      :nickname,
      :phone,
      :subscribed_to_newsletter,
      :use_secondary_address,
      primary_address_attributes: address_strong_params,
      secondary_address_attributes: address_strong_params,
    ]
  end

  def authenticatable_salt
    "#{super}#{sign_out_salt_part}"
  end

  def sign_out_everywhere!
    self.update_column(:sign_out_salt_part, SecureRandom.hex)
  end

  private
    def validate_first_name_and_last_name?
      invitation_accepted_at?
    end

    def validate_phone?
      Rails.application.config.folio_users_require_phone
    end

    def should_subscribe_to_newsletter?
      # skip users that
      # - haven't accepted invitaton
      # - haven't confirmed their email address
      return if created_by_invite? && !invitation_accepted_at?
      return if !confirmed_at? && confirmation_required_for_invited?

      subscribed_to_newsletter?
    end

    def subscription_email
      email || authentications.order(id: :asc).first.email
    end

    def subscription_merge_vars
      {
        "FNAME" => first_name,
        "LNAME" => last_name,
      }.compact
    end

    def update_has_generated_password
      if will_save_change_to_encrypted_password? && !will_save_change_to_has_generated_password?
        self.has_generated_password = false
      end
    end
end

# == Schema Information
#
# Table name: folio_users
#
#  id                        :bigint(8)        not null, primary key
#  email                     :string
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0), not null
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :inet
#  last_sign_in_ip           :inet
#  confirmation_token        :string
#  confirmed_at              :datetime
#  confirmation_sent_at      :datetime
#  unconfirmed_email         :string
#  first_name                :string
#  last_name                 :string
#  admin_note                :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  invitation_token          :string
#  invitation_created_at     :datetime
#  invitation_sent_at        :datetime
#  invitation_accepted_at    :datetime
#  invitation_limit          :integer
#  invited_by_type           :string
#  invited_by_id             :integer
#  invitations_count         :integer          default(0)
#  nickname                  :string
#  use_secondary_address     :boolean          default(FALSE)
#  primary_address_id        :bigint(8)
#  secondary_address_id      :bigint(8)
#  subscribed_to_newsletter  :boolean          default(FALSE)
#  has_generated_password    :boolean          default(FALSE)
#  phone                     :string
#  crossdomain_devise_token  :string
#  crossdomain_devise_set_at :datetime
#  sign_out_salt_part        :string
#
# Indexes
#
#  index_folio_users_on_confirmation_token                 (confirmation_token) UNIQUE
#  index_folio_users_on_crossdomain_devise_token           (crossdomain_devise_token)
#  index_folio_users_on_email                              (email)
#  index_folio_users_on_invitation_token                   (invitation_token) UNIQUE
#  index_folio_users_on_invited_by_id                      (invited_by_id)
#  index_folio_users_on_invited_by_type_and_invited_by_id  (invited_by_type,invited_by_id)
#  index_folio_users_on_primary_address_id                 (primary_address_id)
#  index_folio_users_on_reset_password_token               (reset_password_token) UNIQUE
#  index_folio_users_on_secondary_address_id               (secondary_address_id)
#
