# frozen_string_literal: true

class Folio::Account < Folio::ApplicationRecord
  include Folio::Devise::DeliverLater

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :invitable

  validate :validate_role
  validates :first_name, :last_name, presence: true

  attribute :skip_password_validation, :boolean, default: false

  has_many :created_console_notes, class_name: "Folio::ConsoleNote",
                                   inverse_of: :created_by,
                                   foreign_key: :created_by_id,
                                   dependent: :nullify

  has_many :closed_console_notes, class_name: "Folio::ConsoleNote",
                                  inverse_of: :closed_by,
                                  foreign_key: :closed_by_id,
                                  dependent: :nullify

  pg_search_scope :by_query,
                  against: %i[first_name last_name email],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  scope :ordered, -> { order(created_at: :desc) }

  scope :by_is_active, -> (b) {
    unless b.nil?
      where(is_active: b)
    else
      where(is_active: true)
    end
  }

  scope :by_role, -> (role) {
    where(role:)
  }

  def can_manage_sidekiq?
    Folio::ConsoleAbility.new(self).can?(:manage, :sidekiq)
  end

  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def remember_me
    super.nil? ? "1" : super
  end

  alias :to_label :full_name
  alias :title :full_name

  def active_for_authentication?
    # remember to call the super
    # then put our own check to determine "active" state using
    # our own "is_active" column
    super && self.is_active?
  end

  def human_role_name
    if role
      self.class.human_role_name(role)
    end
  end

  def account_roles_for_select
    if role_index = self.class.roles.find_index(role)
      self.class.roles[role_index..-1]
    else
      []
    end
  end

  def self.clears_page_cache_on_save?
    false
  end

  def self.roles
    # keep the order by strength (strongest first)!
    %w[superuser administrator manager]
  end

  def self.roles_for_select(selectable_roles = nil)
    (selectable_roles || roles).map do |role|
      [human_attribute_name("role/#{role}"), role]
    end
  end

  def self.human_role_name(role)
    human_attribute_name("role/#{role}")
  end

  def password_required?
    if skip_password_validation?
      false
    else
      !persisted? || !password.nil? || !password_confirmation.nil?
    end
  end

  def authenticatable_salt
    "#{super}#{sign_out_salt_part}"
  end

  def sign_out_everywhere!
    self.update_column(:sign_out_salt_part, SecureRandom.hex)
  end

  private
    def validate_role
      if self.class.roles.exclude?(role)
        self.errors.add :role, :invalid
      end
    end
end

# == Schema Information
#
# Table name: folio_accounts
#
#  id                        :bigint(8)        not null, primary key
#  email                     :string           default(""), not null
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0), not null
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string
#  last_sign_in_ip           :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  first_name                :string
#  last_name                 :string
#  role                      :string
#  is_active                 :boolean          default(TRUE)
#  invitation_token          :string
#  invitation_created_at     :datetime
#  invitation_sent_at        :datetime
#  invitation_accepted_at    :datetime
#  invitation_limit          :integer
#  invited_by_type           :string
#  invited_by_id             :bigint(8)
#  invitations_count         :integer          default(0)
#  crossdomain_devise_token  :string
#  crossdomain_devise_set_at :datetime
#  sign_out_salt_part        :string
#
# Indexes
#
#  index_folio_accounts_on_crossdomain_devise_token  (crossdomain_devise_token)
#  index_folio_accounts_on_email                     (email) UNIQUE
#  index_folio_accounts_on_invitation_token          (invitation_token) UNIQUE
#  index_folio_accounts_on_invitations_count         (invitations_count)
#  index_folio_accounts_on_invited_by                (invited_by_type,invited_by_id)
#  index_folio_accounts_on_invited_by_id             (invited_by_id)
#  index_folio_accounts_on_reset_password_token      (reset_password_token) UNIQUE
#
