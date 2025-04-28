# frozen_string_literal: true

Rails.application.config.session_store :cookie_store,
                                       expire_after: 12.hours,
                                       secure: !Rails.env.development? && !Rails.env.test?,
                                       httponly: true,
                                       same_site: :lax
