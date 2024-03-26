# frozen_string_literal: true

if !Rails.env.development? || defined?(ViewComponent)
  Rails.application.config.view_component.capture_compatibility_patch_enabled = true
end
