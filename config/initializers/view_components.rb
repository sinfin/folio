# frozen_string_literal: true

require "view_component"

if !Rails.env.development? || defined?(ViewComponent)
  Rails.application.config.view_component.capture_compatibility_patch_enabled = true
end
