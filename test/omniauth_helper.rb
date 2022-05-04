# frozen_string_literal: true

OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL = "omniauth@default.email"

def create_omniauth_authentication(email: OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL, nickname: "Lorem ipsum")
  Folio::Omniauth::Authentication.from_omniauth_auth(omniauth_authentication_openstruct(email:, nickname:))
end

def omniauth_authentication_hash(email: OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL, nickname: "Lorem ipsum")
  {
    provider: "facebook",
    uid: "1234567890123456",
    info: OpenStruct.new(
      "email": email,
      "name": nickname,
      "image": "http://placekitten.com/200/300"
    ),
    credentials: OpenStruct.new(
      "token": "EAAJK7OgLFysBACykjlr7olJguYwq0dN8VbysLsD4koeM8mlvohNjvlpK0YhtwiU8O3kdpDZCZAFAUFGtvdWa5S2458ZCzLKO0ZBeb1RG1tTA9vZBpmEbPZARB1CFZAbfopXZCVlEuBBYKowfC0JWEIiJZBEWglDdx9kvuZCg30OTAtrgZDZD",
      "expires_at": 1618746336,
      "expires": true
    ),
    extra: OpenStruct.new(
      raw_info: {
        "name" => nickname,
        "email" => email,
        "id" => "1234567890123456",
      }
    )
  }
end

def omniauth_authentication_openstruct(email: OMNIAUTH_AUTHENTICATION_DEFAULT_TEST_EMAIL, nickname: "Lorem ipsum")
  OpenStruct.new(omniauth_authentication_hash(email:, nickname:))
end

OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(omniauth_authentication_hash)
