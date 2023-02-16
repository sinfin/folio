# frozen_string_literal: true

Rails.application.config.responders.flash_keys = %i[success error]

Responders::FlashResponder.flash_keys = Rails.application.config.responders.flash_keys
