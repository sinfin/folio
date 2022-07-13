# frozen_string_literal: true

class Folio::Omniauth::Authentication < Folio::ApplicationRecord
  self.table_name = "folio_omniauth_authentications"

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    optional: true,
                    inverse_of: :authentications

  validates :nickname, :access_token,
            presence: true

  validates :email,
            format: { with: Folio::EMAIL_REGEXP },
            if: :email?

  def human_provider
    self.class.human_provider(provider)
  end

  def self.human_provider(provider)
    I18n.t("folio.devise.omniauth.providers.#{provider}", default: "Oauth")
  end

  def self.from_request(request)
    from_omniauth_auth(request.env["omniauth.auth"])
  end

  def self.from_omniauth_auth(o)
    # return nil if o.blank?

    auth = find_or_initialize_by(provider: o.provider, uid: o.uid)
    auth.email = o.info.email if o.info.email.present?
    auth.nickname = o.info.username || o.info.nickname || o.info.name
    auth.raw_info = o.extra.raw_info
    auth.access_token = o.credentials.token
    auth.save!

    auth
  end
end

# == Schema Information
#
# Table name: folio_omniauth_authentications
#
#  id               :bigint(8)        not null, primary key
#  folio_user_id    :bigint(8)
#  uid              :string
#  provider         :string
#  email            :string
#  nickname         :string
#  access_token     :string
#  raw_info         :json
#  conflict_token   :string
#  conflict_user_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_folio_omniauth_authentications_on_folio_user_id  (folio_user_id)
#
