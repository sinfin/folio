# frozen_string_literal: true

class Folio::User < Folio::ApplicationRecord
  include Folio::Audited::Model
  include Folio::Devise::DeliverLater
  include Folio::HasAddresses
  include Folio::HasNewsletterSubscriptions
  include Folio::HasSiteRoles

  # used to validate before inviting from console in /console/users/new
  attribute :skip_password_validation, :boolean, default: false

  # used to handle address validation when changing password
  attr_accessor :devise_resetting_password

  belongs_to :source_site, class_name: "Folio::Site",
                           required: false
  belongs_to :auth_site, class_name: "Folio::Site",
                         required: true

  selected_device_modules = %i[
    database_authenticatable
    recoverable
    rememberable
    trackable
    invitable
    timeoutable
    lockable
  ]

  if Rails.application.config.folio_users_confirmable
    selected_device_modules << :confirmable
  elsif Rails.application.config.folio_users_confirm_email_change
    selected_device_modules << :confirmable

    def self.should_confirm_email_change?
      true
    end
  end

  selected_device_modules << :omniauthable if Rails.application.config.folio_users_omniauth_providers.present?

  devise_options = {
    omniauth_providers: Rails.application.config.folio_users_omniauth_providers.presence
  }.compact

  devise(*selected_device_modules, devise_options)

  include Folio::IsSiteLockable # must be after Devise

  has_many :authentications, class_name: "Folio::Omniauth::Authentication",
                             foreign_key: :folio_user_id,
                             inverse_of: :user,
                             dependent: :destroy

  has_many :created_console_notes, class_name: "Folio::ConsoleNote",
                                   inverse_of: :created_by,
                                   foreign_key: :created_by_id,
                                   dependent: :nullify

  has_many :closed_console_notes, class_name: "Folio::ConsoleNote",
                                  inverse_of: :closed_by,
                                  foreign_key: :closed_by_id,
                                  dependent: :nullify

  validate :validate_one_of_names
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  validates :email,
            uniqueness: { scope: :auth_site, case_sensitive: false },
            presence: true,
            format: { with: Folio::EMAIL_REGEXP }

  validates_presence_of     :password, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :password, within: Devise.password_length, allow_blank: true

  validates :phone,
            phone: true,
            if: :validate_phone?

  validates :born_at,
            presence: true,
            if: :born_at_required?

  validate :validate_password_complexity

  after_invitation_accepted :create_newsletter_subscriptions

  before_update :update_has_generated_password

  before_create :set_preferred_locale

  pg_search_scope :by_query,
                  against: [:email, :last_name, :first_name, :company_name, :nickname],
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  scope :ordered, -> { order(id: :desc) }
  scope :superadmins, -> { where(superadmin: true) }
  scope :by_role, -> (role) { role == "superadmin" ? superadmins : where(id: Folio::SiteUserLink.by_roles([role]).select(:user_id)) }
  scope :by_site, -> (site) do
    s_site = ::Folio::Current.enabled_site_for_crossdomain_devise || site
    where(auth_site: s_site)
  end
  scope :by_auth_site, -> (site) { where(auth_site: site) }

  scope :by_address_identification_number_query, -> (q) {
    subselect = Folio::Address::Base.where("identification_number LIKE ?", "%#{q}%").select(:id)
    where(primary_address_id: subselect).or(where(secondary_address_id: subselect))
  }

  scope :currently_editing_url, -> (url) do
    where(console_url: url).where("console_url_updated_at > ?", 5.minutes.ago)
  end

  scope :locked_for, -> (site) {
    joins(:site_user_links).merge(Folio::SiteUserLink.by_site(site).locked)
  }

  scope :unlocked_for, -> (site) {
    where.not(id: Folio::SiteUserLink.by_site(site).locked.select(:user_id))
  }

  scope :by_locked, -> (locked_param) {
    case locked_param
    when true, "true"
      locked_for(Folio::Current.site)
    when false, "false"
      unlocked_for(Folio::Current.site)
    else
      all
    end
  }

  pg_search_scope :by_full_name_query,
                  against: %i[last_name first_name company_name],
                  ignoring: :accents,
                  using: { trigram: { word_similarity: true } }

  pg_search_scope :by_addresses_query,
                  associated_against: {
                    primary_address: %i[name company_name address_line_1 address_line_2 zip city],
                    secondary_address: %i[name company_name address_line_1 address_line_2 zip city],
                  },
                  ignoring: :accents,
                  using: { trigram: { word_similarity: true } }

  pg_search_scope :by_email_query_tsearch,
                  against: %i[email],
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  pg_search_scope :by_email_query_trigram,
                  against: %i[email],
                  ignoring: :accents,
                  using: { trigram: { word_similarity: true } }

  scope :by_email_query, -> (email) {
    if email && email.match?(Folio::EMAIL_REGEXP)
      by_email_query_tsearch(email)
    else
      by_email_query_trigram(email)
    end
  }

  audited only: %i[email unconfirmed_email first_name last_name company_name nickname phone subscribed_to_newsletter superadmin bank_account_number],
          relations: %i[site_user_links],
          console: false

  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    elsif company_name.present?
      company_name
    else
      email
    end
  end

  def to_label
    if first_name.present? || last_name.present?
      full_name
    elsif company_name.present?
      company_name
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

  def auth_site_title
    auth_site&.title
  end

  def <=>(other)
    res = self.full_name <=> other.full_name
    return res unless res.zero?

    self.id <=> other.id
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
    %i[id first_name last_name company_name nickname email phone created_at sign_in_count last_sign_in_at admin_note]
  end

  def csv_attributes(controller = nil)
    self.class.csv_attribute_names.map do |attr|
      send(attr)
    end
  end

  def reset_password(new_password, new_password_confirmation)
    self.devise_resetting_password = true
    super
  end

  def self.new_from_auth(auth)
    user = self.new

    user.email = auth.email

    if Rails.application.config.folio_users_confirm_email_change
      user.confirmed_at = Time.current
    end

    if auth.nickname.present?
      ary = auth.nickname.split(/\s+/, 2)
      user.first_name = ary[0]
      user.last_name = ary[1]
    end

    user.authentications << auth

    user
  end

  def self.controller_strong_params_for_create
    [
      :first_name,
      :last_name,
      :company_name,
      :nickname,
      :phone,
      :subscribed_to_newsletter,
      :use_secondary_address,
      primary_address_attributes: Folio::Address::Primary.strong_params,
      secondary_address_attributes: Folio::Address::Secondary.strong_params,
    ] + additional_controller_strong_params_for_create
  end

  def self.additional_controller_strong_params_for_create
    [:born_at]
  end

  def authenticatable_salt
    "#{super}#{sign_out_salt_part}"
  end

  def sign_out_everywhere!
    self.update_column(:sign_out_salt_part, SecureRandom.hex)
  end

  def acquire_orphan_records!(old_session_id:)
  end

  def create_site_links_for(sites)
    sites.compact.uniq.each do |site|
      su_links = site_user_links.by_site(site)
      su_links.create!(roles: []) if su_links.blank?
    end
  end

  def update_console_url!(console_url)
    update_columns(console_url:,
                   console_url_updated_at: Time.current)
  end

  def can_manage_sidekiq?
    can_now?(:manage, :sidekiq, site: Folio::Current.main_site)
  end

  def can_now?(action, subject = nil, site: nil)
    site ||= (subject&.try(:site) || ::Folio::Current.main_site)
    subject = site if subject.blank?
    ability = ::Folio::Current.ability || Folio::Ability.new(self, site)
    can_now_by_ability?(ability, action, subject)
  end

  def can_now_by_ability?(ability, action, subject)
    return false if self.new_record?
    return false unless ability.can?(action, subject)

    # user is able to do action, but can it be triggered now?
    if subject.respond_to?(:currently_available_actions)
      subject.currently_available_actions(self).include?(action)
    else
      true
    end
  end

  def currently_allowed_actions_with(subject, site: nil)
    return [] unless subject.respond_to?(:currently_available_actions)

    site ||= subject&.try(:site)
    subject = site if subject.blank?
    ability = Folio::Ability.new(self, site)

    subject.currently_available_actions(self).select { |action| ability.can?(action, subject) }
  end

  def make_clones_to_all_linked_sites!
    unless valid?
      Rails.logger.error("user #{self.attributes.slice("id", "email")} is invalid #{self.errors.full_messages}")
      return
    end

    if site_user_links.size == 1 # no need to do clones
      self.update!(auth_site_id: site_user_links.first.site_id)
    else
      site_user_links.each do |site_link|
        make_clone_for_site_link(site_link)
      end
    end
  end

  def make_clone_for_site_link(site_link)
    return self if site_link.site_id == self.auth_site_id
    # superadmins have only one account on main site
    return nil if superadmin? && site_link.site_id != Folio::Current.main_site.id

    new_user = self.class.unscoped.where(auth_site_id: site_link.site_id, email:)

    if new_user.blank?
      # create without callbacks
      result = self.class.unscoped.insert self.attributes
                                              .except("skip_password_validation", "id")
                                              .merge({ "created_at" => Time.current,
                                                      "updated_at" => Time.current,
                                                      "reset_password_token" => nil,
                                                      "invitation_token" => nil,
                                                      "auth_site_id" => site_link.site_id })
      if result.rows.first.nil?
        Rails.logger.error("result is nil for link #{site_link.to_json} +  user #{self.attributes.slice("id", "email", "superadmin")}")
        return nil
      end
      new_user = self.class.unscoped.find(result.rows.first.first)
      new_user.primary_address = self.primary_address&.dup
      new_user.secondary_address = self.secondary_address&.dup
    end

    # NOT COPYING: authentications, console_notes
    new_user.save!
    site_link.update!(user: new_user)

    yield(new_user) if block_given?

    new_user.save!
    new_user
  end

  def born_at_required?
    false
  end

  private
    # Override of Devise method to scope authentication by zone.
    def self.find_for_authentication(warden_params)
      email = warden_params[:email]
      site = ::Folio::Current.enabled_site_for_crossdomain_devise || ::Folio::Site.find(warden_params[:auth_site_id])

      user = site.auth_users.find_by(email:)

      if user.nil?
        if Rails.application.config.folio_crossdomain_devise
          crossdomain_site = Folio::Current.enabled_site_for_crossdomain_devise

          if crossdomain_site.present? && site != crossdomain_site
            user = crossdomain_site.auth_users.superadmins.find_by(email:)
          end
        else
          user = Folio::User.superadmins.find_by(email:)
        end
      end

      user
    end

    # used by Devise to lookup for user when reseting pasword etc.
    def self.find_or_initialize_with_errors(required_attributes, attributes, error = :invalid)
      if required_attributes == [:email]
        required_attributes << :auth_site_id
      end

      super(required_attributes, attributes, error)
    end

    def validate_names?
      invitation_accepted_at?
    end

    def validate_phone?
      return true if Rails.application.config.folio_users_require_phone
      phone.present?
    end

    def validate_one_of_names
      return unless validate_names?

      if first_name.blank? && last_name.blank? && company_name.blank?
        errors.add(:first_name, :blank)
        errors.add(:last_name, :blank)
      end
    end

    def newsletter_subscriptions_enabled?
      # skip users that
      # - haven't accepted invitation
      # - haven't confirmed their email address
      return false if created_by_invite? && !invitation_accepted_at?
      return false if !confirmed_at? && confirmation_required_for_invited?

      true
    end

    def should_subscribe_to_newsletter?
      newsletter_subscriptions_enabled? && subscribed_to_newsletter?
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

    def set_preferred_locale
      self.preferred_locale = I18n.locale.to_s if preferred_locale.blank?
    end

    def validate_password_complexity
      return if password.blank?
      return unless Devise.password_length.include?(password.length)

      if password.length < 48
        has_uppercase = password =~ /[A-Z]/
        has_lowercase = password =~ /[a-z]/
        has_digit = password =~ /[0-9]/
        has_special = password =~ /[^a-zA-Z0-9\s]/

        errors.add(:password, :missing_uppercase) unless has_uppercase
        errors.add(:password, :missing_lowercase) unless has_lowercase
        errors.add(:password, :missing_digit) unless has_digit
        errors.add(:password, :missing_special) unless has_special
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
#  invited_by_id             :bigint(8)
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
#  source_site_id            :bigint(8)
#  superadmin                :boolean          default(FALSE), not null
#  console_url               :string
#  console_url_updated_at    :datetime
#  degree_pre                :string(32)
#  degree_post               :string(32)
#  phone_secondary           :string
#  born_at                   :date
#  bank_account_number       :string
#  company_name              :string
#  time_zone                 :string           default("Prague")
#  auth_site_id              :bigint(8)        not null
#  preferred_locale          :string
#  console_preferences       :jsonb
#  failed_attempts           :integer          default(0), not null
#  unlock_token              :string
#  locked_at                 :datetime
#
# Indexes
#
#  index_folio_users_on_auth_site_id                       (auth_site_id)
#  index_folio_users_on_confirmation_token                 (confirmation_token) UNIQUE
#  index_folio_users_on_crossdomain_devise_token           (crossdomain_devise_token)
#  index_folio_users_on_email                              (email)
#  index_folio_users_on_invitation_token                   (invitation_token) UNIQUE
#  index_folio_users_on_invited_by_id                      (invited_by_id)
#  index_folio_users_on_invited_by_type_and_invited_by_id  (invited_by_type,invited_by_id)
#  index_folio_users_on_primary_address_id                 (primary_address_id)
#  index_folio_users_on_reset_password_token               (reset_password_token) UNIQUE
#  index_folio_users_on_secondary_address_id               (secondary_address_id)
#  index_folio_users_on_source_site_id                     (source_site_id)
#
# Foreign Keys
#
#  fk_rails_...  (auth_site_id => folio_sites.id)
#
