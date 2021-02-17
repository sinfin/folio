# frozen_string_literal: true

class Folio::Omniauth::Authentication < Folio::ApplicationRecord
  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    optional: true

  validates :nickname, :access_token,
            presence: true

  validates :email,
            format: { with: Folio::EMAIL_REGEXP },
            if: :email?

  def human_provider
    I18n.t("folio.devise.omniauth.providers.#{provider}")
  end

  def find_or_create_user!
    return user if user.present?

    if email.present?
      existing_user = Folio::User.find_by(email: email)
    else
      existing_user = nil
    end

    if existing_user
      false
    else
      Folio::User.create!(password: Devise.friendly_token[0, 20],
                          nickname: nickname,
                          authentications: [self],
                          email: email)
    end
  end

  def self.from_request(request)
    o = request.env["omniauth.auth"]

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
#  id            :bigint(8)        not null, primary key
#  folio_user_id :bigint(8)
#  uid           :string
#  provider      :string
#  email         :string
#  nickname      :string
#  access_token  :string
#  raw_info      :json
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_folio_omniauth_authentications_on_folio_user_id  (folio_user_id)
#
